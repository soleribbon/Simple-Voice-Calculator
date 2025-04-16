//
//  CloudKitManager.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 14/04/25.
//

import Foundation
import CloudKit

class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    private let cloudItemLimit = 100
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    // Record types
    private let historyRecordType = "HistoryItem"
    private let favoriteRecordType = "FavoriteItem"
    
    // Published properties for status
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    // Keep track of sync operations in progress
    private var currentHistorySyncTask: Task<Void, Never>?
    private var currentFavoriteSyncTask: Task<Void, Never>?
    
    init() {
        // Get the default container for your app
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
        
        // Set up subscriptions for real-time updates
        Task {
            await setupSubscriptions()
        }
    }
    
    // MARK: - Account Status
    
    func checkAccountStatus() async -> Bool {
        do {
            let status = try await container.accountStatus()
            
            // Log the status for debugging
            //            print("CloudKit account status: \(status.rawValue)")
            
            // Only consider available as a success
            return status == .available
        } catch {
            // Captured detailed error for logging
            print("CloudKit account status error: \(error.localizedDescription)")
            
            // Check if it's a network error
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                // These are common network errors
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet,
                    NSURLErrorNetworkConnectionLost,
                NSURLErrorDataNotAllowed:
                    print("Network connectivity issue detected")
                default:
                    break
                }
            }
            
            return false
        }
    }
    
    // MARK: - Subscriptions for Real-time Updates
    
    func setupSubscriptions() async {
        guard await shouldSync() else { return }
        
        do {
            let predicate = NSPredicate(value: true)
            
            // First, check if subscription already exists
            let historySubscriptionID = "history-changes"
            do {
                let _ = try await privateDatabase.subscription(for: historySubscriptionID)
                print("History subscription already exists")
            } catch {
                // Subscription doesn't exist, create it
                let subscription = CKQuerySubscription(
                    recordType: historyRecordType,
                    predicate: predicate,
                    subscriptionID: historySubscriptionID,
                    options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
                )
                
                let notificationInfo = CKSubscription.NotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notificationInfo
                
                try await privateDatabase.save(subscription)
                print("Created history subscription")
            }
            
            // Do the same for favorites subscription
            let favoritesSubscriptionID = "favorites-changes"
            do {
                let _ = try await privateDatabase.subscription(for: favoritesSubscriptionID)
                print("Favorites subscription already exists")
            } catch {
                // Subscription doesn't exist, create it
                let subscription = CKQuerySubscription(
                    recordType: favoriteRecordType,
                    predicate: predicate,
                    subscriptionID: favoritesSubscriptionID,
                    options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
                )
                
                let notificationInfo = CKSubscription.NotificationInfo()
                notificationInfo.shouldSendContentAvailable = true
                subscription.notificationInfo = notificationInfo
                
                try await privateDatabase.save(subscription)
                print("Created favorites subscription")
            }
        } catch {
            print("Failed to set up CloudKit subscriptions: \(error)")
        }
    }
    
    // MARK: - History Items Sync
    
    func saveHistoryItems(_ items: [HistoryItem]) async {
        // Cancel any in-progress history sync
        currentHistorySyncTask?.cancel()
        
        // Start a new save task
        currentHistorySyncTask = Task {
            guard await shouldSync() else { return }
            
            // Set syncing status on main thread
            await MainActor.run {
                self.isSyncing = true
            }
            
            do {
                // Limit the items to the maximum cloud storage limit
                let limitedItems = items.count > cloudItemLimit
                ? Array(items.prefix(cloudItemLimit))
                : items
                
                // 1. Get all existing records first
                let query = CKQuery(recordType: historyRecordType, predicate: NSPredicate(value: true))
                let existingRecordsResult = try await privateDatabase.records(matching: query)
                let existingRecords = existingRecordsResult.matchResults.compactMap { try? $0.1.get() }
                
                // 2. Delete all existing records
                let recordIDs = existingRecords.map { $0.recordID }
                
                // 3. Create new records for all limited local items
                var recordsToSave = [CKRecord]()
                
                for item in limitedItems {
                    let record = CKRecord(recordType: historyRecordType)
                    record["id"] = item.id.uuidString
                    record["equation"] = item.equation
                    record["result"] = item.result
                    record["date"] = item.date
                    
                    recordsToSave.append(record)
                }
                
                print("Replacing cloud history: Deleting \(recordIDs.count), adding \(recordsToSave.count)")
                
                // 4. Execute the modification in one operation
                if !recordIDs.isEmpty || !recordsToSave.isEmpty {
                    _ = try await privateDatabase.modifyRecords(saving: recordsToSave, deleting: recordIDs)
                }
                
                // Update UI state on main thread
                await MainActor.run {
                    self.lastSyncDate = Date()
                    self.syncError = nil
                    self.isSyncing = false
                }
                
            } catch {
                // Handle error on main thread
                await MainActor.run {
                    self.syncError = error.localizedDescription
                    self.isSyncing = false
                }
                print("Error saving history items to CloudKit: \(error)")
            }
        }
    }
    
    func fetchHistoryItems() async -> [HistoryItem]? {
        guard await shouldSync() else { return nil }
        
        do {
            let query = CKQuery(recordType: historyRecordType, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            let result = try await privateDatabase.records(matching: query)
            let records = result.matchResults.compactMap { try? $0.1.get() }
            
            var historyItems = [HistoryItem]()
            
            for record in records {
                guard let idString = record["id"] as? String,
                      let equation = record["equation"] as? String,
                      let result = record["result"] as? String,
                      let date = record["date"] as? Date,
                      let id = UUID(uuidString: idString) else {
                    continue
                }
                
                let item = HistoryItem(id: id, equation: equation, result: result, date: date)
                historyItems.append(item)
            }
            
            print("Fetched \(historyItems.count) history items from CloudKit")
            return historyItems
            
        } catch {
            print("Error fetching history items from CloudKit: \(error)")
            return nil
        }
    }
    
    // MARK: - Favorite Items Sync
    
    func saveFavoriteItems(_ items: [HistoryItem]) async {
        // Cancel any in-progress favorite sync
        currentFavoriteSyncTask?.cancel()
        
        // Start a new save task
        currentFavoriteSyncTask = Task {
            guard await shouldSync() else { return }
            
            // Set syncing status on main thread
            await MainActor.run {
                self.isSyncing = true
            }
            
            do {
                // Limit the items to the maximum cloud storage limit
                let limitedItems = items.count > cloudItemLimit
                ? Array(items.prefix(cloudItemLimit))
                : items
                
                // 1. Get all existing records first
                let query = CKQuery(recordType: favoriteRecordType, predicate: NSPredicate(value: true))
                let existingRecordsResult = try await privateDatabase.records(matching: query)
                let existingRecords = existingRecordsResult.matchResults.compactMap { try? $0.1.get() }
                
                // 2. Delete all existing records
                let recordIDs = existingRecords.map { $0.recordID }
                
                // 3. Create new records for all limited local items
                var recordsToSave = [CKRecord]()
                
                for item in limitedItems {
                    let record = CKRecord(recordType: favoriteRecordType)
                    record["id"] = item.id.uuidString
                    record["equation"] = item.equation
                    record["result"] = item.result
                    record["date"] = item.date
                    
                    recordsToSave.append(record)
                }
                
                print("Replacing cloud favorites: Deleting \(recordIDs.count), adding \(recordsToSave.count)")
                
                // 4. Execute the modification in one operation
                if !recordIDs.isEmpty || !recordsToSave.isEmpty {
                    _ = try await privateDatabase.modifyRecords(saving: recordsToSave, deleting: recordIDs)
                }
                
                // Update UI state on main thread
                await MainActor.run {
                    self.lastSyncDate = Date()
                    self.syncError = nil
                    self.isSyncing = false
                }
                
            } catch {
                // Handle error on main thread
                await MainActor.run {
                    self.syncError = error.localizedDescription
                    self.isSyncing = false
                }
                print("Error saving favorite items to CloudKit: \(error)")
            }
        }
    }
    
    
    func fetchFavoriteItems() async -> [HistoryItem]? {
        guard await shouldSync() else { return nil }
        
        do {
            let query = CKQuery(recordType: favoriteRecordType, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            
            let result = try await privateDatabase.records(matching: query)
            let records = result.matchResults.compactMap { try? $0.1.get() }
            
            var favoriteItems = [HistoryItem]()
            
            for record in records {
                guard let idString = record["id"] as? String,
                      let equation = record["equation"] as? String,
                      let result = record["result"] as? String,
                      let date = record["date"] as? Date,
                      let id = UUID(uuidString: idString) else {
                    continue
                }
                
                let item = HistoryItem(id: id, equation: equation, result: result, date: date)
                favoriteItems.append(item)
            }
            
            print("Fetched \(favoriteItems.count) favorite items from CloudKit")
            return favoriteItems
            
        } catch {
            print("Error fetching favorite items from CloudKit: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Functions
    
    func clearAllRecords(ofType recordType: String) async {
        guard await shouldSync() else { return }
        
        await MainActor.run {
            self.isSyncing = true
        }
        
        do {
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            let result = try await privateDatabase.records(matching: query)
            let records = result.matchResults.compactMap { try? $0.1.get() }
            
            let recordIDs = records.map { $0.recordID }
            if !recordIDs.isEmpty {
                _ = try await privateDatabase.modifyRecords(saving: [], deleting: recordIDs)
                print("Cleared all \(recordType) records from CloudKit")
                
                // Force empty local data too when a clear is requested
                await MainActor.run {
                    if recordType == historyRecordType {
                        let historyManager = HistoryManager()
                        historyManager.historyItems = []
                        historyManager.saveHistory()
                    } else if recordType == favoriteRecordType {
                        let favoritesManager = FavoritesManager()
                        favoritesManager.favoriteItems = []
                        favoritesManager.saveFavorites()
                    }
                }
            }
            
            await MainActor.run {
                self.lastSyncDate = Date()
                self.isSyncing = false
            }
        } catch {
            print("Error clearing \(recordType) records: \(error)")
            await MainActor.run {
                self.isSyncing = false
            }
        }
    }
    // MARK: - Force Sync Operations
    
    func forceFullSync() async {
        guard await shouldSync() else { return }
        
        await MainActor.run {
            self.isSyncing = true
        }
        
        let historyManager = HistoryManager()
        let favoritesManager = FavoritesManager()
        
        // Check network connectivity first
        let isCloudAvailable = await checkAccountStatus()
        
        if !isCloudAvailable {
            print("CloudKit not available - skipping sync")
            await MainActor.run {
                self.syncError = "iCloud not available"
                self.isSyncing = false
            }
            return
        }
        
        // SIMPLIFIED APPROACH: Check both local and cloud item counts
        let localHistory = historyManager.historyItems
        let localFavorites = favoritesManager.favoriteItems
        
        let cloudHistory = await fetchHistoryItems() ?? []
        let cloudFavorites = await fetchFavoriteItems() ?? []
        
        // For history items
        if localHistory.count >= cloudHistory.count {
            // Local has more or equal items - prioritize local
            print("Prioritizing local history (\(localHistory.count) items) over cloud (\(cloudHistory.count) items)")
            await saveHistoryItems(localHistory) // This will automatically apply the 100-item limit
        } else {
            // Cloud has more items - merge with local
            print("Merging cloud history (\(cloudHistory.count) items) with local (\(localHistory.count) items)")
            
            await MainActor.run {
                let localIds = Set(localHistory.map { $0.id.uuidString })
                var mergedHistory = localHistory
                
                // Add any cloud items that don't exist locally
                for cloudItem in cloudHistory {
                    if !localIds.contains(cloudItem.id.uuidString) {
                        mergedHistory.append(cloudItem)
                    }
                }
                
                // Sort and save
                historyManager.historyItems = mergedHistory.sorted { $0.date > $1.date }
                historyManager.saveHistory()
            }
        }
        
        // For favorite items
        if localFavorites.count >= cloudFavorites.count {
            // Local has more or equal items - prioritize local
            print("Prioritizing local favorites (\(localFavorites.count) items) over cloud (\(cloudFavorites.count) items)")
            await saveFavoriteItems(localFavorites) // This will automatically apply the 100-item limit
        } else {
            // Cloud has more items - merge with local
            print("Merging cloud favorites (\(cloudFavorites.count) items) with local (\(localFavorites.count) items)")
            
            await MainActor.run {
                let localIds = Set(localFavorites.map { $0.id.uuidString })
                var mergedFavorites = localFavorites
                
                // Add any cloud items that don't exist locally
                for cloudItem in cloudFavorites {
                    if !localIds.contains(cloudItem.id.uuidString) {
                        mergedFavorites.append(cloudItem)
                    }
                }
                
                // Sort and save
                favoritesManager.favoriteItems = mergedFavorites.sorted { $0.date > $1.date }
                favoritesManager.saveFavorites()
            }
        }
        
        await MainActor.run {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
    }
    
    // MARK: - Subscription Status
    
    func shouldSync() async -> Bool {
        // Check if user is a PRO subscriber
        let isProUser = StoreManager.shared.isSubscriptionActive
        
        // Return early if not a pro user
        if !isProUser {
            return false
        }
        
        // Also check network connectivity
        let isCloudAvailable = await checkAccountStatus()
        
        // Both conditions need to be true for sync
        return isProUser && isCloudAvailable
    }
    
    
    
    // MARK: - Diagnostics
    
    func logCloudKitDiagnostics() async {
        print("=== CloudKit Diagnostics ===")
        print("Container identifier: \(container.containerIdentifier ?? "unknown")")
        
        do {
            let status = try await container.accountStatus()
            print("Account status: \(status.rawValue)")
            switch status {
            case .available:
                print("iCloud account is available")
            case .noAccount:
                print("No iCloud account found")
            case .restricted:
                print("iCloud account is restricted")
            case .couldNotDetermine:
                print("Could not determine iCloud account status")
            case .temporarilyUnavailable:
                print("iCloud temporarily unavailable")
            @unknown default:
                print("Unknown iCloud account status")
            }
        } catch {
            print("Failed to get account status: \(error.localizedDescription)")
        }
        
        print("=== End CloudKit Diagnostics ===")
    }
}
