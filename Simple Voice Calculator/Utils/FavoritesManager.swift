//
//  FavoritesManager.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 14/04/25.
//

import Foundation
import Combine
import Mixpanel

class FavoritesManager: ObservableObject {
    @Published var favoriteItems: [HistoryItem] = []
    private let favoritesKey = "calculatorFavorites"
    
    init() {
        loadFavorites()
    }
    
    // MARK: - Favorites Management
    
    func toggleFavorite(item: HistoryItem) {
        if isFavorite(item) {
            removeFromFavorites(item)
        } else {
            addToFavorites(item)
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
        if let encoded = try? JSONEncoder().encode(favoriteItems) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([HistoryItem].self, from: data) {
            favoriteItems = decoded
        }
    }
    
    // MARK: - Cleanup
    
    func clearAllFavorites() {
        favoriteItems = []
        saveFavorites()
        
        // Track event
        Mixpanel.mainInstance().track(event: "clearedAllFavorites")
    }
    
    // MARK: - Synchronization
    
    // Called when history items are deleted to ensure favorites stay in sync
    func syncWithHistory(historyItems: [HistoryItem]) {
        // Keep only favorites that still exist in history
        favoriteItems = favoriteItems.filter { favorite in
            historyItems.contains(where: { $0.id == favorite.id })
        }
        saveFavorites()
    }
}
