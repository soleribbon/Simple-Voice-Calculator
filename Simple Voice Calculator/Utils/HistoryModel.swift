//
//  HistoryManager.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 26/03/25.
//

import Foundation
import Combine

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
    
    @Published var isRegUser: Bool = false // TOGGLE FOR TESTING false = subscriber
    @Published var historyViewCount: Int = 0
    private let historyViewCountKey = "historyViewCount"
    @Published var showHistoryBadge: Bool = true
    private let showHistoryBadgeKey = "showHistoryBadge"
    
    // Track valid equation to save
    var hasValidEquationToSave: Bool {
        // Basic validation
        guard !currentEquation.isEmpty && currentResult != "Invalid Equation" else {
            return false
        }
        
        // Get the components of the equation
        let components = parseEquationComponents(from: currentEquation)
        
        // Only save if there are multiple components (indicating a calculation)
        // This handles all cases including negative numbers
        return components.count > 1
    }
    
    init() {
        loadHistory()
        loadHistoryViewCount()
        loadShowHistoryBadge()
    }
    func deleteItems(_ items: [HistoryItem]) {
        for item in items {
            if let index = historyItems.firstIndex(where: { $0.id == item.id }) {
                historyItems.remove(at: index)
            }
        }
        saveHistory()
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
                
                // Keep only the last 20 items to prevent excessive storage
                if historyItems.count > 20 {
                    historyItems = Array(historyItems.prefix(20))
                }
                
                saveHistory()
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
        if let encoded = try? JSONEncoder().encode(historyItems) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    // Load history from UserDefaults
    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            historyItems = decoded
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
    
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
