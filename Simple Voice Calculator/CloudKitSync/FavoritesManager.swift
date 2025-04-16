//
//  FavoritesManager.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 14/04/25.
//

import Foundation
import Combine
import Mixpanel
import CloudKit

class FavoritesManager: ObservableObject {
    @Published var favoriteItems: [HistoryItem] = []
    private let favoritesKey = "calculatorFavorites"
    
    private let favoritesLimit = 100
    
    @Published var isSyncing: Bool = false
    @Published var lastSyncDate: Date?
    // Timer for automatic syncing
    private var syncTimer: Timer?
    
    init() {
        loadFavorites()
        setupSyncTimer()
    }
    deinit {
        syncTimer?.invalidate()
    }
    
    // Setup a timer to periodically check for sync
    private func setupSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.checkAndPerformSync()
        }
    }
    
    // MARK: - Sync Methods
    func checkAndPerformSync() {
        Task {
            // Always save locally regardless of connectivity
            saveFavorites()
            
            // Only attempt cloud sync if conditions are right
            if await CloudKitManager.shared.shouldSync() {
                await syncWithCloud()
            }
        }
    }
    
    
    
    
    func syncWithCloud() async {
        // If already syncing, exit early
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
        
        
        // 1. Get cloud data
        let cloudItems = await CloudKitManager.shared.fetchFavoriteItems() ?? []
        
        // 2. Count local and cloud items
        let localItemCount = self.favoriteItems.count
        let cloudItemCount = cloudItems.count
        
        // 3. If local has fewer items than cloud, there may be new items to merge
        //    If local has more or equal items than cloud, prioritize local (could be offline additions)
        if localItemCount < cloudItemCount {
            print("Cloud has more favorite items than local - merging new items")
            
            await MainActor.run {
                let localIds = Set(self.favoriteItems.map { $0.id.uuidString })
                
                // Add any cloud items that don't exist locally
                for cloudItem in cloudItems {
                    if !localIds.contains(cloudItem.id.uuidString) {
                        self.favoriteItems.append(cloudItem)
                    }
                }
                
                // Sort by date
                self.favoriteItems.sort { $0.date > $1.date }
                
                // Save locally
                self.saveFavorites()
            }
        } else {
            print("Local has more or equal favorite items than cloud - prioritizing local")
            
            // Just upload local data to replace cloud
            await CloudKitManager.shared.saveFavoriteItems(self.favoriteItems)
        }
        
        // Update UI to show syncing is complete
        await MainActor.run {
            self.lastSyncDate = Date()
            self.isSyncing = false
        }
    }
    
    
    
    func performManualSync() {
        Task {
            await syncWithCloud()
        }
    }
    
    
    // MARK: - Favorites Management
    
    func toggleFavorite(item: HistoryItem) {
        // Track current state before change
        let wasFavorite = isFavorite(item)
        
        // Perform local change
        if wasFavorite {
            removeFromFavorites(item)
        } else {
            // Check if we're at the limit before adding
            if favoriteItems.count >= favoritesLimit {
                // Remove oldest favorite to make room
                if let oldest = favoriteItems.min(by: { $0.date < $1.date }) {
                    removeFromFavorites(oldest)
                }
            }
            addToFavorites(item)
        }
        
        // Always save locally first
        saveFavorites()
        
        // Try to sync immediately to reflect changes across devices
        Task(priority: .userInitiated) {
            if await CloudKitManager.shared.shouldSync() {
                // Simply replace cloud data with local data
                await CloudKitManager.shared.saveFavoriteItems(favoriteItems)
            }
        }
    }
    
    
    func isFavorite(_ item: HistoryItem) -> Bool {
        return favoriteItems.contains(where: { $0.id == item.id })
    }
    
    private func addToFavorites(_ item: HistoryItem) {
        // Only add if not already in favorites
        if !isFavorite(item) {
            favoriteItems.append(item)
            saveFavorites()
            
            // Track event
            Mixpanel.mainInstance().track(event: "addedFavorite", properties: [
                "equation": item.equation
            ])
        }
    }
    
    private func removeFromFavorites(_ item: HistoryItem) {
        favoriteItems.removeAll(where: { $0.id == item.id })
        saveFavorites()
        
        // Track event
        Mixpanel.mainInstance().track(event: "removedFavorite", properties: [
            "equation": item.equation
        ])
    }
    
    // MARK: - Persistence
    
    func saveFavorites() {
        do {
            let encoded = try JSONEncoder().encode(favoriteItems)
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
            UserDefaults.standard.synchronize() // Force immediate save
        } catch {
            print("Error encoding favorites: \(error)")
        }
    }
    
    
    func loadFavorites() {
        do {
            if let data = UserDefaults.standard.data(forKey: favoritesKey) {
                let decoded = try JSONDecoder().decode([HistoryItem].self, from: data)
                favoriteItems = decoded
            }
        } catch {
            print("Error decoding favorites: \(error)")
            // If can't decode, start with empty array rather than crash
            favoriteItems = []
        }
    }
    
    
    // MARK: - Cleanup
    
    func clearAllFavorites() {
        // Always clear locally
        favoriteItems = []
        saveFavorites()
        
        // Try to sync if possible - immediately
        Task(priority: .userInitiated) {
            if await CloudKitManager.shared.shouldSync() {
                // Clear all cloud records
                await CloudKitManager.shared.clearAllRecords(ofType: "FavoriteItem")
            }
        }
        
        // Track event
        Mixpanel.mainInstance().track(event: "clearedAllFavorites")
    }
    
    // MARK: - Synchronization
    
    // Called when history items are deleted to ensure favorites stay in sync
    func syncWithHistory(historyItems: [HistoryItem]) {
        // Keep track of any changes
        let previousCount = favoriteItems.count
        
        // Keep only favorites that still exist in history
        favoriteItems = favoriteItems.filter { favorite in
            historyItems.contains(where: { $0.id == favorite.id })
        }
        
        // If any items were removed, save changes
        if previousCount != favoriteItems.count {
            saveFavorites()
            
            // Try to sync with CloudKit if possible
            Task {
                if await CloudKitManager.shared.shouldSync() {
                    await CloudKitManager.shared.saveFavoriteItems(favoriteItems)
                }
            }
        }
    }
}

extension FavoritesManager {
    var isRegUser: Bool {
        return !StoreManager.shared.isSubscriptionActive
    }
}
