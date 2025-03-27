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

    // Track if we have a valid equation to save
    var hasValidEquationToSave: Bool {
        !currentEquation.isEmpty && currentResult != "Invalid Equation"
    }

    init() {
        loadHistory()
    }

    // Update the current equation (but don't save to history yet)
    func updateCurrentEquation(equation: String, result: String) {
        currentEquation = equation
        currentResult = result
    }

    // Save the current equation to history
    func saveCurrentEquationToHistory() {
        // Only save if we have a valid equation and result
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
}
