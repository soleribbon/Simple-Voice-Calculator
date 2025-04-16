//
//  StoreKitStuff.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 14/05/24.
//

//
//  StoreKitStuff.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 14/05/24.
//

import Foundation
import StoreKit
import Mixpanel
import SwiftUI

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    // MARK: - Published Properties
    @Published var products: [SKProduct] = []
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var is1CoffeePurchaseProcessing = false
    @Published var is5CoffeesPurchaseProcessing = false
    @Published var is10CoffeesPurchaseProcessing = false
    
    // MARK: - Subscription Properties
    @Published var isSubscriptionActive: Bool = false
    private var transactionListener: Task<Void, Error>? = nil
    private(set) var subscriptionExpirationDate: Date?
    
    // MARK: - Shared Instance
    static let shared = StoreManager()
    private var request: SKProductsRequest!
    
    // MARK: - Initialization
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        
        // Notification observer for Superwall subscription
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProPurchase(_:)),
            name: NSNotification.Name("ProSubscriptionPurchased"),
            object: nil
        )
        
        setupSubscriptionMonitoring()
        
        // Immediately check subscription status on launch
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    
    @objc func handleProPurchase(_ notification: Notification) {
        // Check if notification includes a flag indicating this is a new purchase
        if let userInfo = notification.userInfo,
           let isNewPurchase = userInfo["isNewPurchase"] as? Bool,
           isNewPurchase {
            
            // Only show thank you message for new purchases
            showProSubscriptionThanks()
        }
        
        // Always update subscription status
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    private func setupSubscriptionMonitoring() {
        // Start listening for subscription changes
        transactionListener = createTransactionListener()
        
        // Check subscription status immediately
        Task {
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Product Fetching
    func startRequest(with identifiers: [String]) {
        let productIdentifiers = Set(identifiers)
        request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
        }
    }
    
    // MARK: - Payment Queue
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchasedTransaction(transaction)
            case .failed:
                handleFailedTransaction(transaction)
            default:
                break
            }
        }
    }
    
    private func handlePurchasedTransaction(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            self.showAlert = true
            
            switch transaction.payment.productIdentifier {
            case "CoffeeTip1":
                self.is1CoffeePurchaseProcessing = false
                self.alertMessage = "Thank you for your donation ❤️"
                Mixpanel.mainInstance().track(event: "1CoffeePurchased")
            case "CoffeeTip5":
                self.is5CoffeesPurchaseProcessing = false
                self.alertMessage = "Thank you for your donation ❤️"
                Mixpanel.mainInstance().track(event: "5CoffeesPurchased")
            case "CoffeeTip10":
                self.is10CoffeesPurchaseProcessing = false
                self.alertMessage = "Thank you for your donation ❤️"
                Mixpanel.mainInstance().track(event: "10CoffeesPurchased")
            case "pro_monthly", "pro_yearly", "pro_monthly_discounted", "pro_yearly_discounted":
                self.alertMessage = "Thank you for your support! Enjoy PRO Mode ✨"
                Mixpanel.mainInstance().track(event: "SubscriptionPurchased")
                // Check subscription status immediately using Task
                Task {
                    await self.checkSubscriptionStatus()
                }
            default:
                self.alertMessage = "Purchase successful!"
                print("Unknown product identifier: \(transaction.payment.productIdentifier)")
            }
            
            // Prompt for review
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    func showProSubscriptionThanks() {
        DispatchQueue.main.async {
            self.showAlert = true
            self.alertMessage = "Thank you for your support! Enjoy PRO Mode ✨"
            
            // Prompt for review
            if let windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }
    
    private func handleFailedTransaction(_ transaction: SKPaymentTransaction) {
        DispatchQueue.main.async {
            if let error = transaction.error as NSError?, error.code != SKError.paymentCancelled.rawValue {
                self.showAlert = true
                
                // Use the correct message for donations vs. subscriptions
                if ["CoffeeTip1", "CoffeeTip5", "CoffeeTip10"].contains(transaction.payment.productIdentifier) {
                    self.alertMessage = "Donation failed - Please try again."
                } else {
                    self.alertMessage = "Purchase failed - Please try again."
                }
            } else {
                print("Transaction canceled by user")
            }
            
            // Reset the processing flag based on the product identifier
            switch transaction.payment.productIdentifier {
            case "CoffeeTip1":
                self.is1CoffeePurchaseProcessing = false
            case "CoffeeTip5":
                self.is5CoffeesPurchaseProcessing = false
            case "CoffeeTip10":
                self.is10CoffeesPurchaseProcessing = false
            default:
                print("Reset processing for: \(transaction.payment.productIdentifier)")
            }
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    // MARK: - Purchase Methods
    func purchaseProduct(withIdentifier productIdentifier: String) {
        resetPurchaseProcessingFlags()
        
        // Based on the productIdentifier, set the corresponding processing flag to true
        switch productIdentifier {
        case "CoffeeTip1":
            is1CoffeePurchaseProcessing = true
        case "CoffeeTip5":
            is5CoffeesPurchaseProcessing = true
        case "CoffeeTip10":
            is10CoffeesPurchaseProcessing = true
        default:
            print("Processing purchase for: \(productIdentifier)")
        }
        
        if let product = products.first(where: { $0.productIdentifier == productIdentifier }) {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            // Reset the flags if the product was not found
            resetPurchaseProcessingFlags()
            showAlert = true
            alertMessage = "Product not found."
        }
    }
    
    private func resetPurchaseProcessingFlags() {
        is1CoffeePurchaseProcessing = false
        is5CoffeesPurchaseProcessing = false
        is10CoffeesPurchaseProcessing = false
    }
    
    // MARK: - StoreKit 2 Subscription Handling
    private func createTransactionListener() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transactions in real-time
            for await verification in StoreKit.Transaction.updates {
                // Process the verification result
                switch verification {
                case .verified(let transaction):
                    // Only process subscription products
                    if transaction.productType == .autoRenewable {
                        // Mark transaction as finished (required for StoreKit)
                        await transaction.finish()
                        // Update subscription status
                        await self.checkSubscriptionStatus()
                    }
                case .unverified:
                    // Invalid transaction, ignore
                    print("Received unverified transaction")
                }
            }
        }
    }
    
    func checkSubscriptionStatus() async {
        // Use task-local variables to track results
        var foundActiveSubscription = false
        var newExpirationDate: Date? = nil
        
        // Get all current entitlements (active purchases)
        for await verification in StoreKit.Transaction.currentEntitlements {
            // Only process verified transactions
            switch verification {
            case .verified(let transaction):
                // Check if this is a subscription
                if transaction.productType == .autoRenewable {
                    // Check if the subscription is still valid (not expired)
                    if let expirationDate = transaction.expirationDate,
                       expirationDate > Date() {
                        // Active subscription found
                        foundActiveSubscription = true
                        newExpirationDate = expirationDate
                        break
                    }
                }
            case .unverified:
                continue
            }
        }
        
        // Now capture the final values before passing to MainActor
        let finalActive = foundActiveSubscription
        let finalExpDate = newExpirationDate
        
        // Only update the published property once, after all verification is complete
        await MainActor.run {
            // Only notify if there's an actual change
            let statusChanged = (self.isSubscriptionActive != finalActive)
            
            // Update properties
            self.isSubscriptionActive = finalActive
            self.subscriptionExpirationDate = finalExpDate
            
            // Post notification only if status actually changed
            if statusChanged {
                NotificationCenter.default.post(
                    name: NSNotification.Name("SubscriptionStatusChanged"),
                    object: nil,
                    userInfo: ["isSubscriptionActive": self.isSubscriptionActive]
                )
            }
        }
    }
    
    func restorePurchases() {
        // Wrap the async call in a Task
        Task {
            do {
                // Trigger app store sync
                try await AppStore.sync()
                // Check status again after sync
                await checkSubscriptionStatus()
            } catch {
                print("Failed to restore purchases: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Convenience Methods
    func formatExpirationDate() -> String? {
        guard let date = subscriptionExpirationDate else { return nil }
        
        let df = DateFormatter()
        df.dateStyle = .long          // e.g. “Apr 30, 2025”
        df.timeStyle = .none
        
        let dateString = df.string(from: date)
        
        return String(
            format: NSLocalizedString("SUBSCRIPTION_RENEWS_ON",
                                      comment: "Label preceding renewal date"),
            dateString)
    }
    
    var isRegUser: Bool {
        return !isSubscriptionActive
    }
    
    
}

