
import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var helpExpanded = false
    @State private var privacyExpanded = false
    private let productIdentifiers = ["CoffeeTip1", "CoffeeTip5", "CoffeeTip10"]
    @AppStorage("shouldSpeakTotal") var shouldSpeakTotal: Bool = false
    
    @ObservedObject var storeManager = StoreManager()
    @State private var introCoverShowing: Bool = false
    
    @State private var versionNumber: String = "1.9.0"
    
    
    //    @Environment(\.requestReview) var requestReview
    
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
                            Text("**What does the 'Sym' button do?**")
                                .font(.body)
                                .padding(.vertical)
                            Text("The Sym button can be used to insert a desired math symbol where your cursor is placed in the textfield.")
                                .font(.body)
                                .padding(.bottom)
                            
                        }
                        
                        
                        VStack(alignment: .leading) {
                            Text("**How do I edit my voice input?**")
                                .font(.body)
                                .padding(.vertical)
                            Text("You can edit any component of your equation in the 'Equation Components' section. Just tap you desired components and it will be selected in your textfield. Make sure you do not have voice input enabled (button should say 'Start Talking').")
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
                    
                    Button(action: {
                        introCoverShowing = true
                        
                    }, label: {
                        
                        HStack {
                            Image(systemName: "pencil.and.outline")
                                .foregroundColor(.accentColor)
                            Text("Introduction Tutorial")
                            Spacer()
                        }
                    })
                    
                    
                    
                    
                    
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
                        
                        
                        
                    }.accessibilityLabel("About Simple Voice Calculator")
                    Link(destination: URL(string: "https://www.raviheyne.com")!, label: {
                        HStack {
                            Text("💌")
                                .foregroundColor(.accentColor)
                            Text("Contact Developer").foregroundColor(.blue)
                        }
                    }).accessibilityLabel("Contact Developer")
                    
                    //BUTTON TO REQUEST REVIEW - MIGHT DO NOTHING AT ALL DEPENDS ON APPLE ALWAYS
                    //                    Button(action: {
                    //                        requestReview()
                    //                    }, label: {
                    //
                    //
                    //                        HStack{
                    //                            Text("⭐️")
                    //                                .foregroundColor(.accentColor)
                    //                            Text("Leave Review")
                    //                            .foregroundColor(.primary)
                    //                        }
                    //
                    //                    })
                    //
                    
                    GroupBox {
                        
                        
                        // Tip Button for $1
                        VStack (alignment: .center){
                            HStack (alignment: .center){
                                Text("☕️")
                                    .foregroundColor(.accentColor)
                                Text("Tip Developer a Coffee")
                                    .bold()
                                    .minimumScaleFactor(0.4)
                                
                            }.accessibilityLabel("Tip developer a coffee")
                            
                            
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
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.4)
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
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.4)
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
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.4)
                                }
                            }
                            
                            Text("Simple Voice Calculator was made by students.")
                                .font(.caption2)
                                .opacity(0.4)
                                .minimumScaleFactor(0.4)
                                .padding(.top, 4)
                            
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Section(header: Text("Preferences")) {
                    Toggle(isOn: $shouldSpeakTotal) {
                        Text("Announce Total")
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
                        Text(versionNumber)
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
            .fullScreenCover(isPresented: $introCoverShowing, content: {
                ZStack{
                    OnboardingContainerView(isActualIntro: false)
                    VStack {
                        HStack{
                            Spacer()
                            
                            Button(action: {
                                introCoverShowing = false
                            }, label:  {
                                Image(systemName: "xmark")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding(8)
                                
                            })
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                            )
                            .padding()
                        }.padding(.horizontal)
                        Spacer()
                        
                    }
                    
                }
                
                
                
            })
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                            .font(.body)
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


