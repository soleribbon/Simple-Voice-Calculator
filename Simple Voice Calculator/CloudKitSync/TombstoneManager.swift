//
//  TombstoneManager.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 15/04/25.
//

import Foundation

/// Manages deletion records (tombstones) for properly handling sync operations
class TombstoneManager {
    static let shared = TombstoneManager()
    
    // Key constants - use namespaced keys to avoid collisions
    private let historyPrefixUD = "deleted_history_" // For UserDefaults
    private let favoritePrefixUD = "deleted_favorite_" // For UserDefaults
    
    // Use shorter keys for iCloud (it has size limits)
    private let historyPrefixIC = "dh_" // For iCloud KVS
    private let favoritePrefixIC = "df_" // For iCloud KVS
    
    // Main store for deletion records that sync across devices
    private let iCloudStore = NSUbiquitousKeyValueStore.default
    
    // Local store for faster access
    private let localStore = UserDefaults.standard
    
    // Keep in-memory cache for fast lookups
    private var deletedHistoryCache = Set<String>()
    private var deletedFavoriteCache = Set<String>()
    
    init() {
        // Set up notification handler for external changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: iCloudStore
        )
        
        // Force sync and load cache
        syncAndRefresh()
    }
    
    @objc func iCloudStoreDidChange(_ notification: Notification) {
        print("🔄 iCloud KVS changed externally - syncing tombstones")
        syncAndRefresh()
        
        // Notify the app of changes
        NotificationCenter.default.post(name: NSNotification.Name("TombstonesDidChange"), object: nil)
    }
    
    func syncAndRefresh() {
        // Sync with iCloud
        iCloudStore.synchronize()
        
        // Refresh local caches
        refreshCaches()
    }
    
    private func refreshCaches() {
        // Ensure local and iCloud are in sync
        synchronizeStores()
        
        // Refresh memory caches from combined sources
        deletedHistoryCache = Set(getAllDeletedItems(isHistory: true))
        deletedFavoriteCache = Set(getAllDeletedItems(isHistory: false))
        
        print("📋 Refreshed tombstone caches - History: \(deletedHistoryCache.count), Favorites: \(deletedFavoriteCache.count)")
    }
    
    // Ensure UserDefaults and iCloud KVS have the same tombstone data
    private func synchronizeStores() {
        // First, get all data from both stores
        let iCloudHistoryKeys = getAllICloudKeys(isHistory: true)
        let iCloudFavoriteKeys = getAllICloudKeys(isHistory: false)
        let localHistoryKeys = getAllLocalKeys(isHistory: true)
        let localFavoriteKeys = getAllLocalKeys(isHistory: false)
        
        // Sync history tombstones from iCloud to local
        for iCloudKey in iCloudHistoryKeys {
            let localKey = "\(historyPrefixUD)\(iCloudKey)"
            let timestamp = iCloudStore.double(forKey: "\(historyPrefixIC)\(iCloudKey)")
            if timestamp > 0 {
                localStore.set(timestamp, forKey: localKey)
            }
        }
        
        // Sync favorite tombstones from iCloud to local
        for iCloudKey in iCloudFavoriteKeys {
            let localKey = "\(favoritePrefixUD)\(iCloudKey)"
            let timestamp = iCloudStore.double(forKey: "\(favoritePrefixIC)\(iCloudKey)")
            if timestamp > 0 {
                localStore.set(timestamp, forKey: localKey)
            }
        }
        
        // Sync history tombstones from local to iCloud
        for localKey in localHistoryKeys {
            let iCloudKey = "\(historyPrefixIC)\(localKey)"
            let timestamp = localStore.double(forKey: "\(historyPrefixUD)\(localKey)")
            if timestamp > 0 {
                iCloudStore.set(timestamp, forKey: iCloudKey)
            }
        }
        
        // Sync favorite tombstones from local to iCloud
        for localKey in localFavoriteKeys {
            let iCloudKey = "\(favoritePrefixIC)\(localKey)"
            let timestamp = localStore.double(forKey: "\(favoritePrefixUD)\(localKey)")
            if timestamp > 0 {
                iCloudStore.set(timestamp, forKey: iCloudKey)
            }
        }
        
        // Force save changes
        localStore.synchronize()
        iCloudStore.synchronize()
    }
    
    // Get keys from iCloud KVS
    private func getAllICloudKeys(isHistory: Bool) -> [String] {
        let prefix = isHistory ? historyPrefixIC : favoritePrefixIC
        return iCloudStore.dictionaryRepresentation.keys.compactMap { key in
            if key.hasPrefix(prefix) {
                return String(key.dropFirst(prefix.count))
            }
            return nil
        }
    }
    
    // Get keys from UserDefaults
    private func getAllLocalKeys(isHistory: Bool) -> [String] {
        let prefix = isHistory ? historyPrefixUD : favoritePrefixUD
        return localStore.dictionaryRepresentation().keys.compactMap { key in
            // No need for conditional cast since key is already a String
            if key.hasPrefix(prefix) {
                return String(key.dropFirst(prefix.count))
            }
            return nil
        }
    }
    
    // Mark an item as deleted
    func markDeleted(itemId: UUID, isHistory: Bool) {
        let uuid = itemId.uuidString
        let now = Date().timeIntervalSince1970
        
        // Store in both places
        let localKey = isHistory ? "\(historyPrefixUD)\(uuid)" : "\(favoritePrefixUD)\(uuid)"
        let iCloudKey = isHistory ? "\(historyPrefixIC)\(uuid)" : "\(favoritePrefixIC)\(uuid)"
        
        print("🗑️ Marking as deleted: \(uuid), isHistory: \(isHistory)")
        
        // Set in UserDefaults
        localStore.set(now, forKey: localKey)
        localStore.synchronize()
        
        // Set in iCloud KVS
        iCloudStore.set(now, forKey: iCloudKey)
        let syncResult = iCloudStore.synchronize()
        
        print("  ↪️ iCloud sync result: \(syncResult ? "success" : "failure")")
        
        // Update cache
        if isHistory {
            deletedHistoryCache.insert(uuid)
        } else {
            deletedFavoriteCache.insert(uuid)
        }
    }
    
    // Mark multiple items as deleted
    func markBulkDeleted(itemIds: [UUID], isHistory: Bool) {
        let now = Date().timeIntervalSince1970
        
        print("🗑️ Bulk marking \(itemIds.count) items as deleted (isHistory: \(isHistory))")
        
        // Process each item
        for itemId in itemIds {
            let uuid = itemId.uuidString
            
            // Store in both places
            let localKey = isHistory ? "\(historyPrefixUD)\(uuid)" : "\(favoritePrefixUD)\(uuid)"
            let iCloudKey = isHistory ? "\(historyPrefixIC)\(uuid)" : "\(favoritePrefixIC)\(uuid)"
            
            // Set in UserDefaults
            localStore.set(now, forKey: localKey)
            
            // Set in iCloud KVS
            iCloudStore.set(now, forKey: iCloudKey)
            
            // Update cache
            if isHistory {
                deletedHistoryCache.insert(uuid)
            } else {
                deletedFavoriteCache.insert(uuid)
            }
        }
        
        // Force synchronization after all updates
        localStore.synchronize()
        let syncResult = iCloudStore.synchronize()
        print("  ↪️ iCloud sync result: \(syncResult ? "success" : "failure")")
    }
    
    // Check if an item is deleted (fast lookup using cache)
    func isDeleted(itemId: String, isHistory: Bool) -> Bool {
        // Check cache for performance
        return isHistory ? deletedHistoryCache.contains(itemId) : deletedFavoriteCache.contains(itemId)
    }
    
    // Get all deleted items
    func getAllDeletedItems(isHistory: Bool) -> [String] {
        // Force sync before getting items
        syncAndRefresh()
        
        // Get deleted IDs from both stores and combine
        let localIds = getDeletedFromLocal(isHistory: isHistory)
        let iCloudIds = getDeletedFromICloud(isHistory: isHistory)
        
        // Combine and remove duplicates
        return Array(Set(localIds + iCloudIds))
    }
    
    // Get deleted items from UserDefaults
    private func getDeletedFromLocal(isHistory: Bool) -> [String] {
        let prefix = isHistory ? historyPrefixUD : favoritePrefixUD
        
        // Filter keys
        let keys = localStore.dictionaryRepresentation().keys.compactMap { key in
            if key.hasPrefix(prefix), localStore.double(forKey: key) > 0 {
                return String(key.dropFirst(prefix.count))
            }
            return nil
        }
        
        return keys
    }
    
    // Get deleted items from iCloud KVS
    private func getDeletedFromICloud(isHistory: Bool) -> [String] {
        let prefix = isHistory ? historyPrefixIC : favoritePrefixIC
        
        // Filter keys
        let keys = iCloudStore.dictionaryRepresentation.keys.compactMap { key in
            if key.hasPrefix(prefix), iCloudStore.double(forKey: key) > 0 {
                return String(key.dropFirst(prefix.count))
            }
            return nil
        }
        
        return keys
    }
    
    // Clean up old tombstones to prevent storage bloat
    func cleanupOldTombstones() {
        let thirtyDaysAgo = Date().timeIntervalSince1970 - (30 * 24 * 60 * 60)
        var removedCount = 0
        
        // Clean local tombstones
        for key in localStore.dictionaryRepresentation().keys {
            if (key.hasPrefix(historyPrefixUD) || key.hasPrefix(favoritePrefixUD)) {
                let timestamp = localStore.double(forKey: key)
                if timestamp > 0 && timestamp < thirtyDaysAgo {
                    localStore.removeObject(forKey: key)
                    removedCount += 1
                }
            }
        }
        
        // Clean iCloud tombstones
        for key in iCloudStore.dictionaryRepresentation.keys {
            if (key.hasPrefix(historyPrefixIC) || key.hasPrefix(favoritePrefixIC)) {
                let timestamp = iCloudStore.double(forKey: key)
                if timestamp > 0 && timestamp < thirtyDaysAgo {
                    iCloudStore.removeObject(forKey: key)
                    removedCount += 1
                }
            }
        }
        
        if removedCount > 0 {
            print("🧹 Cleaned up \(removedCount) old tombstones")
            localStore.synchronize()
            iCloudStore.synchronize()
            refreshCaches()
        }
    }
    
    // Debug helper
    func debugPrintAllTombstones() {
        print("=== ALL TOMBSTONES ===")
        let historyTombstones = getAllDeletedItems(isHistory: true)
        let favoriteTombstones = getAllDeletedItems(isHistory: false)
        
        print("🔍 Local storage status:")
        print("  UserDefaults synchronize() available: \(localStore.responds(to: #selector(UserDefaults.synchronize)))")
        print("  iCloud KVS synchronize() result: \(iCloudStore.synchronize())")
        
        print("History tombstones (\(historyTombstones.count)):")
        for id in historyTombstones {
            let localKey = "\(historyPrefixUD)\(id)"
            let iCloudKey = "\(historyPrefixIC)\(id)"
            let localTimestamp = localStore.double(forKey: localKey)
            let iCloudTimestamp = iCloudStore.double(forKey: iCloudKey)
            let localDate = Date(timeIntervalSince1970: localTimestamp)
            let iCloudDate = Date(timeIntervalSince1970: iCloudTimestamp)
            print("  \(id)")
            print("    Local: \(localTimestamp > 0 ? localDate.description : "Not set")")
            print("    iCloud: \(iCloudTimestamp > 0 ? iCloudDate.description : "Not set")")
        }
        
        print("Favorite tombstones (\(favoriteTombstones.count)):")
        for id in favoriteTombstones {
            let localKey = "\(favoritePrefixUD)\(id)"
            let iCloudKey = "\(favoritePrefixIC)\(id)"
            let localTimestamp = localStore.double(forKey: localKey)
            let iCloudTimestamp = iCloudStore.double(forKey: iCloudKey)
            let localDate = Date(timeIntervalSince1970: localTimestamp)
            let iCloudDate = Date(timeIntervalSince1970: iCloudTimestamp)
            print("  \(id)")
            print("    Local: \(localTimestamp > 0 ? localDate.description : "Not set")")
            print("    iCloud: \(iCloudTimestamp > 0 ? iCloudDate.description : "Not set")")
        }
        
        print("=== END TOMBSTONES ===")
    }
}
