import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var helpExpanded = false
    @State private var privacyExpanded = false
    private let productIdentifiers = ["CoffeeTip1", "CoffeeTip5", "CoffeeTip10"]
    
    @ObservedObject var storeManager = StoreManager()
    
    
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Quick Help")) {
                    DisclosureGroup(isExpanded: $helpExpanded) {
                        
                        VStack(alignment: .leading) {
                            Text("**What math operators are supported?**")
                                .font(.body)
                                .padding(.vertical)
                            Text("Currently supported operators:")
                                .font(.body)
                            Text("+ - × ÷")
                                .font(.body)
                                .padding(.bottom)
                        }
                        
                        
                        VStack(alignment: .leading) {
                            Text("**What does 'Invalid Equation' mean?**")
                                .font(.body)
                                .padding(.vertical)
                            Text("Invalid Equation is presented when the textfield contains characters that are not valid in a mathematical equation or not currently supported.")
                                .font(.body)
                                .padding(.bottom)
                            
                        }
                        
                        
                        VStack(alignment: .leading) {
                            Text("**How do I edit my voice input?**")
                                .font(.body)
                                .padding(.vertical)
                            Text("Stop voice input. Then, you can edit any component of your equation in the 'Equation Components' section. Just tap you desired components and it will be selected in your textfield.")
                                .font(.body)
                                .padding(.bottom)
                            
                        }
                        
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.accentColor)
                            Text("FAQ")
                            
                        }
                    }
                }
                
                
                Section(header: Text("About & Contact")) {
                    NavigationLink(destination: AboutView())
                    {
                        HStack {
                            Text("ℹ️")
                                .foregroundColor(.accentColor)
                            Text("About Simple Voice Calculator")
                            Spacer()
                        }
                        
                        
                        
                    }
                    Link(destination: URL(string: "https://www.raviheyne.com")!, label: {
                        HStack {
                            Text("💌")
                                .foregroundColor(.accentColor)
                            Text("Contact Developer").foregroundColor(.blue)
                        }
                    })
                    
                    
                    GroupBox {
                        
                        
                        // Tip Button for $1
                        VStack {
                            HStack (alignment: .center) {
                                Button(action: {
                                    storeManager.purchaseProduct(withIdentifier: "CoffeeTip1")
                                }) {
                                    Text("1 Cup")
                                        .bold()
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(.green)
                                        .cornerRadius(10)
                                }
                                Button(action: {
                                    storeManager.purchaseProduct(withIdentifier: "CoffeeTip5")
                                }) {
                                    Text("5 Cups")
                                        .bold()
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(.teal)
                                        .cornerRadius(10)
                                }
                                Button(action: {
                                    storeManager.purchaseProduct(withIdentifier: "CoffeeTip10")
                                }) {
                                    Text("10 Cups")
                                        .bold()
                                        .font(.body)
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(.blue)
                                        .cornerRadius(10)
                                }
                            }
                            
                            Text("Simple Voice Calculator was made by students.")
                                .font(.caption2)
                                .opacity(0.4)
                        }
                    } label: {
                        HStack {
                            Text("☕️")
                                .foregroundColor(.accentColor)
                            Text("Tip developer a coffee")
                        }
                    }
                }
                Section(header: Text("Privacy")) {
                    DisclosureGroup(isExpanded: $privacyExpanded) {
                        Text("We take privacy so seriously, we do not collect any information at all! Once a calculation is cleared, it is gone forever.")
                        Text("*Speech data is sent to Apple to ensure transcription accuracy")
                            .font(.caption2)
                            .opacity(0.4)
                    } label: {
                        HStack {
                            Image(systemName: "shield")
                                .foregroundColor(.accentColor)
                            Text("Privacy")
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("1.0.7")
                            .font(.body)
                            .opacity(0.6)
                    }
                }
            }
            .onAppear {
                storeManager.startRequest(with: productIdentifiers)
            }
            .alert(isPresented: $storeManager.showAlert) {
                Alert(title: Text(storeManager.alertMessage))
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

class StoreManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    var request: SKProductsRequest!
    @Published var products: [SKProduct] = []
    @Published var showAlert = false
    @Published var alertMessage = ""
    
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
                // Handle the purchase
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "Thank you for your donation ❤️"
                }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .failed:
                // Handle the failure
                //                DispatchQueue.main.async {
                //                    self.showAlert = true
                //                    self.alertMessage = "Donation failed - Please try again."
                //                }
                print("Donation failed...")
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }
    
    func purchaseProduct(withIdentifier productIdentifier: String) {
        if let product = products.first(where: { $0.productIdentifier == productIdentifier }) {
            print(product)
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
}

