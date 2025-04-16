//
//  HistoryManager.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 26/03/25.
//

import Foundation
import Combine
import TipKit
import Mixpanel
import CloudKit

// History item model
struct HistoryItem: Identifiable, Codable {
    var id = UUID()
    var equation: String
    var result: String
    var date: Date
    
    // Helper computed property to check if item is from today
    var isFromToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    // Helper computed property to check if item is from yesterday
    var isFromYesterday: Bool {
        Calendar.current.isDateInYesterday(date)
    }
}

// Manager class to handle history data
class HistoryManager: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    private let historyKey = "calculatorHistory"
    
    
    // Current equation that hasn't been saved to history yet
    @Published var currentEquation: String = ""
    @Published var currentResult: String = ""
    
    @Published var historyViewCount: Int = 0
    private let historyViewCountKey = "historyViewCount"
    @Published var showHistoryBadge: Bool = true
    private let showHistoryBadgeKey = "showHistoryBadge"
    
    private let cloudStorageLimit = 100
    
    //CLOUDKIT
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    private var syncTimer: Timer?
    
    init() {
        loadHistory()
        loadHistoryViewCount()
        loadShowHistoryBadge()
        setupSyncTimer()
    }
    
    deinit {
        syncTimer?.invalidate()
    }
    
    private var historyLimit: Int {
        let storedLimit = UserDefaults.standard.integer(forKey: "historyLimit")
        return storedLimit > 0 ? storedLimit : 25 // Default to 25 if not set
    }
    
    
    var isRegUser: Bool {
        return !StoreManager.shared.isSubscriptionActive
    }

    // Periodically check for sync
    private func setupSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.checkAndPerformSync()
        }
    }
    
    //Manual Sync
    func performManualSync() {
        Task(priority: .userInitiated) {
            await syncWithCloud()
        }
    }
    
    // Track valid equation to save
    var hasValidEquationToSave: Bool {
        // Basic validation
        guard !currentEquation.isEmpty && currentResult != "Invalid Equation" else {
            return false
        }
        
        // Get the components of the equation
        let components = parseEquationComponents(from: currentEquation)
        
        // Case 1: Multiple components (indicating a calculation)
        if components.count > 1 {
            return true
        }
        
        // Case 2: Check for operations inside parentheses like "(232-42)"
        if currentEquation.hasPrefix("(") && currentEquation.hasSuffix(")") {
            // Remove the outer parentheses
            let insideParentheses = String(currentEquation.dropFirst().dropLast())
            
            // Look for operation symbols inside the parentheses
            if insideParentheses.contains(where: { "+-×÷*/".contains($0) }) {
                return true
            }
        }
        
        // If none of the conditions are met, don't save
        return false
    }
    
    
    // MARK: - Sync Methods
    func checkAndPerformSync() {
        Task {
            // Always save locally regardless of connectivity
            saveHistory()
            
            // Only attempt cloud sync if conditions are right
            if await CloudKitManager.shared.shouldSync() {
                // Before syncing, ensure we're not trying to sync too many items
                let itemsToSync = historyItems.count > cloudStorageLimit
                ? Array(historyItems.prefix(cloudStorageLimit))
                : historyItems
                
                // Use CloudKit manager to sync the limited set
                let cloudKitManager = CloudKitManager.shared
                await cloudKitManager.saveHistoryItems(itemsToSync)
            }
        }
    }
    
    func syncWithCloud() async {
        // If already syncing, exit early to prevent duplicated efforts
        if isSyncing { return }
        
        // Update UI to show syncing status
        await MainActor.run {
            self.isSyncing = true
        }
        
        // Check if should perform a sync
        guard await CloudKitManager.shared.shouldSync() else {
            await MainActor.run {
                self.isSyncing = false
            }
            return
        }
        
        // SIMPLIFIED APPROACH:
        // 1. Get cloud data
        let cloudItems = await CloudKitManager.shared.fetchHistoryItems() ?? []
        
        // 2. Count local and cloud items
        let localItemCount = self.historyItems.count
        let cloudItemCount = cloudItems.count
        
        // 3. SIMPLIFIED DECISION: If local has fewer items than cloud, there may be new items to merge
        //    If local has more or equal items than cloud, prioritize local (could be offline additions)
        if localItemCount < cloudItemCount {
            print("Cloud has more history items than local - merging new items")
            
            await MainActor.run {
                let localIds = Set(self.historyItems.map { $0.id.uuidString })
                
                // Add any cloud items that don't exist locally
                for cloudItem in cloudItems {
                    if !localIds.contains(cloudItem.id.uuidString) {
                        self.historyItems.append(cloudItem)
                    }
                }
                
                // Sort by date
                self.historyItems.sort { $0.date > $1.date }
                
                // Save locally
                self.saveHistory()
            }
        } else {
            print("Local has more or equal history items than cloud - prioritizing local")
            
            // Just upload local data to replace cloud
            await CloudKitManager.shared.saveHistoryItems(self.historyItems)
        }
        
        // Update UI to show syncing is complete
        await MainActor.run {
            self.lastSyncDate = Date()
            self.isSyncing = false
        }
    }
    
    
    // Modify the deleteItems method in HistoryManager.swift
    func deleteItems(_ items: [HistoryItem], favoritesManager: FavoritesManager? = nil) {
        // Remove items from local storage
        for item in items {
            if let index = historyItems.firstIndex(where: { $0.id == item.id }) {
                historyItems.remove(at: index)
            }
        }
        
        // Always save locally first
        saveHistory()
        
        // Sync with favorites if provided
        if let favoritesManager = favoritesManager {
            favoritesManager.syncWithHistory(historyItems: historyItems)
        }
        
        // Try to sync immediately to reflect changes across devices
        Task(priority: .userInitiated) {
            if await CloudKitManager.shared.shouldSync() {
                // Simply replace cloud data with local data
                await CloudKitManager.shared.saveHistoryItems(historyItems)
            }
        }
    }
    
    
    
    
    
    // Update the current equation (but don't save to history yet)
    func updateCurrentEquation(equation: String, result: String) {
        currentEquation = equation
        currentResult = result
    }
    
    
    // Save the current equation to history
    func saveCurrentEquationToHistory() {
        // Only save if valid equation and result
        if hasValidEquationToSave {
            // Check if this equation is already in history (avoid duplicates)
            if !historyItems.contains(where: { $0.equation == currentEquation }) {
                let newItem = HistoryItem(equation: currentEquation, result: currentResult, date: Date())
                historyItems.insert(newItem, at: 0)
                
                // Keep only the last 25 items to prevent excessive storage
                if historyItems.count > 25 {
                    historyItems = Array(historyItems.prefix(25))
                }
                
                saveHistory()
                
                // Sync changes to iCloud
                checkAndPerformSync()
            }
            
            // Reset current equation after saving
            currentEquation = ""
            currentResult = ""
        }
    }
    
    // Get today's history items
    var todayItems: [HistoryItem] {
        historyItems.filter { $0.isFromToday }
    }
    
    // Get yesterday's history items
    var yesterdayItems: [HistoryItem] {
        historyItems.filter { $0.isFromYesterday }
    }
    
    // Save history to UserDefaults
    func saveHistory() {
        do {
            let encoded = try JSONEncoder().encode(historyItems)
            UserDefaults.standard.set(encoded, forKey: historyKey)
            UserDefaults.standard.synchronize() // Force immediate save
        } catch {
            print("Error encoding history items: \(error)")
        }
    }
    
    // Load history from UserDefaults
    func loadHistory() {
        do {
            if let data = UserDefaults.standard.data(forKey: historyKey) {
                let decoded = try JSONDecoder().decode([HistoryItem].self, from: data)
                historyItems = decoded
            }
        } catch {
            print("Error decoding history items: \(error)")
            // If can't decode, start with empty array rather than crash
            historyItems = []
        }
    }
    
    func loadHistoryViewCount() {
        historyViewCount = UserDefaults.standard.integer(forKey: historyViewCountKey)
    }
    
    func loadShowHistoryBadge() {
        showHistoryBadge = UserDefaults.standard.bool(forKey: showHistoryBadgeKey)
        
        // Set the initial value if it doesn't exist yet
        if !UserDefaults.standard.contains(key: showHistoryBadgeKey) {
            showHistoryBadge = true
            UserDefaults.standard.set(true, forKey: showHistoryBadgeKey)
        }
    }
    func incrementHistoryViewCount() {
        historyViewCount += 1
        
        // Hide badge after 2 views
        if historyViewCount >= 2 {
            showHistoryBadge = false
        }
        
        // Save updated values
        UserDefaults.standard.set(historyViewCount, forKey: historyViewCountKey)
        UserDefaults.standard.set(showHistoryBadge, forKey: showHistoryBadgeKey)
    }
    
    // Update markHistoryAsViewed method
    func markHistoryAsViewed() {
        // Mark the history as viewed to dismiss tips
        FeatureTipsManager.shared.markFeatureAsSeen(.history)
        
        // Update view count and badge
        incrementHistoryViewCount()
        
    }
    
    func syncFavorites(favoritesManager: FavoritesManager) {
        // Update favorites when history is modified
        favoritesManager.syncWithHistory(historyItems: historyItems)
    }
    
}
// Extension to add the history limit update method to HistoryManager
extension HistoryManager {
    
    
    func updateHistoryLimit(_ newLimit: Int) {
        // Save the user's preference
        UserDefaults.standard.set(newLimit, forKey: "historyLimit")
        
        // Trim existing history if needed to match user preference
        if historyItems.count > newLimit {
            historyItems = Array(historyItems.prefix(newLimit))
            saveHistory()
        }
        
        // Track the event
        Mixpanel.mainInstance().track(event: "changedHistoryLimit", properties: ["limit": newLimit])
        
        // Let the user know about sync being limited if they selected a higher value
        if newLimit > cloudStorageLimit {
            // This could be handled via a one-time alert or tip if desired
            print("User selected \(newLimit) history items, but only \(cloudStorageLimit) will sync")
        }
    }
    
    
    
}


extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
