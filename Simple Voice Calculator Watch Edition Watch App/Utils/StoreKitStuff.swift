//
//  StoreKitStuff.swift
//  Simple Voice Calculator Watch Edition Watch App
//
//  Created by Ravi Heyne on 30/09/24.
//


import Foundation
import StoreKit

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = StoreManager()
    
    let productIdentifiers = ["CoffeeTip1", "CoffeeTip5", "CoffeeTip10"]
    
    var request: SKProductsRequest!
    @Published var products: [SKProduct] = []
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var is1CoffeePurchaseProcessing = false
    @Published var is2CoffeesPurchaseProcessing = false
    @Published var is3CoffeesPurchaseProcessing = false
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
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
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Thank you for your donation ❤️"
                    
                    // Reset the processing flag based on the product identifier
                    switch transaction.payment.productIdentifier {
                    case "CoffeeTip1":
                        self.is1CoffeePurchaseProcessing = false
                        //                        Mixpanel.mainInstance().track(event: "1CoffeePurchased")
                    case "CoffeeTip5":
                        self.is2CoffeesPurchaseProcessing = false
                        //                        Mixpanel.mainInstance().track(event: "2CoffeesPurchased")
                    case "CoffeeTip10":
                        self.is3CoffeesPurchaseProcessing = false
                        //                        Mixpanel.mainInstance().track(event: "3CoffeesPurchased")
                    default:
                        print("Unknown product identifier")
                    }
                    
                    // Prompt for review
                    //                    if let windowScene = UIApplication.shared.connectedScenes
                    //                        .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    //                        SKStoreReviewController.requestReview(in: windowScene)
                    //                    }
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
                
                
            case .failed:
                DispatchQueue.main.async {
                    if let error = transaction.error as NSError?, error.code != SKError.paymentCancelled.rawValue {
                        DispatchQueue.main.async {
                            self.showAlert = true
                            self.alertMessage = "Donation failed - Please try again."
                        }
                    } else {
                        // If user cancelled the transaction, do not show an alert
                        print("Transaction Failed + didn't show alert to user :/ check on this")
                    }
                    
                    // Reset the processing flag based on the product identifier
                    switch transaction.payment.productIdentifier {
                    case "CoffeeTip1":
                        self.is1CoffeePurchaseProcessing = false
                    case "CoffeeTip5":
                        self.is2CoffeesPurchaseProcessing = false
                    case "CoffeeTip10":
                        self.is3CoffeesPurchaseProcessing = false
                    default:
                        print("Unknown product identifier")
                    }
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                
            default:
                break
            }
        }
    }
    
    
    
    func purchaseProduct(withIdentifier productIdentifier: String) {
        resetPurchaseProcessingFlags()
        
        // Based on the productIdentifier, set the corresponding processing flag to true
        switch productIdentifier {
        case "CoffeeTip1":
            is1CoffeePurchaseProcessing = true
        case "CoffeeTip5":
            is2CoffeesPurchaseProcessing = true
        case "CoffeeTip10":
            is3CoffeesPurchaseProcessing = true
        default:
            print("Unknown product identifier")
        }
        
        if let product = products.first(where: { $0.productIdentifier == productIdentifier }) {
            print(product)
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
        is2CoffeesPurchaseProcessing = false
        is3CoffeesPurchaseProcessing = false
    }
}

@MainActor
class PurchaseModel: ObservableObject {
    let productIdentifiers = ["CoffeeTip1", "CoffeeTip5", "CoffeeTip10"]
    
    @Published var products: [Product] = []
    
    func fetchProducts() async {
        
        
        Task.init(priority: .background){
            do {
                let products = try await Product.products(for: productIdentifiers)
                print(products)
                DispatchQueue.main.async {
                    self.products = products
                    print(products)
                }
            }
            catch {
                print(error)
            }
            
        }
        
    }
    
    func purchase() {
        
        Task.init(priority: .background){
            guard let product = products.first else { return }
            do {
                let result = try await product.purchase()
                print(result)
            }
            catch {
                print(error)
            }
            
        }
    }
}

