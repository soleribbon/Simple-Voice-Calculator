
import SwiftUI
import Mixpanel

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var helpExpanded = false
    @State private var privacyExpanded = false
    private let productIdentifiers = ["CoffeeTip1", "CoffeeTip5", "CoffeeTip10"]
    @AppStorage("shouldSpeakTotal") var shouldSpeakTotal: Bool = false
    
    @EnvironmentObject var historyManager: HistoryManager
    
    // History limit options for Pro users
    private let historyLimitOptions = [25, 50, 100, 250]
    @AppStorage("historyLimit") var historyLimit: Int = 25
    
    @State private var isShareSheetPresented = false
    
    @ObservedObject var storeManager = StoreManager()
    @State private var introCoverShowing: Bool = false
    @State private var versionNumber: String = Bundle.main.releaseVersionNumber ?? "1.0"
    
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
                        HStack (alignment: .center) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.accentColor)
                            Text("FAQ")
                            
                        }
                    }
                    
                    Button(action: {
                        introCoverShowing = true
                        
                    }, label: {
                        
                        HStack (alignment: .center){
                            Image(systemName: "pencil.and.outline")
                                .foregroundColor(.accentColor)
                            Text("Introduction Tutorial")
                            Spacer()
                        }
                    })
                    
                    Button(action: {
                        // Track analytics
                        Mixpanel.mainInstance().track(event: "sharedApp")
                        
                        // Present share sheet via state
                        isShareSheetPresented = true
                    }) {
                        HStack(alignment: .center) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.accentColor)
                            Text("Tell Friends")
                            Spacer()
                        }
                    }
                    .accessibilityLabel("Tell a Friend")
                    
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
                    
                    
                    
                    Link(destination: URL(string: "mailto:raviheyne@gmail.com")!, label: {
                        HStack {
                            Text("💌")
                                .foregroundColor(.accentColor)
                            Text("Contact Developer")
                        }
                    }).accessibilityLabel("Contact Developer")
                    
                    if !historyManager.isRegUser {
                        // Show Pro Badge for premium users
                        HStack {
                            Text("💎")
                            Text("Your current plan:")
                            Text("PRO")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                            
                        }
                        .padding(.vertical, 6)
                    } else {
                        // Only show tip section for free users
                        GroupBox {
                            VStack (alignment: .center) {
                                HStack (alignment: .center) {
                                    Text("☕️")
                                        .foregroundColor(.accentColor)
                                    Text("Tip Developer a Coffee")
                                        .bold()
                                        .minimumScaleFactor(0.4)
                                }
                                .accessibilityLabel("Tip developer a coffee")
                                
                                HStack(alignment: .center) {
                                    DonationButton(title: "1 Cup", color: .green, isProcessing: storeManager.is1CoffeePurchaseProcessing) {
                                        storeManager.purchaseProduct(withIdentifier: "CoffeeTip1")
                                    }
                                    DonationButton(title: "5 Cups", color: .teal, isProcessing: storeManager.is5CoffeesPurchaseProcessing) {
                                        storeManager.purchaseProduct(withIdentifier: "CoffeeTip5")
                                    }
                                    DonationButton(title: "10 Cups", color: .blue, isProcessing: storeManager.is10CoffeesPurchaseProcessing) {
                                        storeManager.purchaseProduct(withIdentifier: "CoffeeTip10")
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
                    
                    
                    
                }
                
                Section(header: Text("Preferences")) {
                    Toggle(isOn: $shouldSpeakTotal) {
                        Text("Announce Total")
                    }
                    .tint(.blue)
                    .onChange(of: shouldSpeakTotal, perform: handleToggleChange)
                    
                    // History Limit Picker for Pro users
                    if !historyManager.isRegUser {
                        Picker("History Limit", selection: $historyLimit) {
                            ForEach(historyLimitOptions, id: \.self) { limit in
                                Text("\(limit) equations").tag(limit)
                            }
                        }
                        .onChange(of: historyLimit) { newValue in
                            // Update history manager's limit
                            historyManager.updateHistoryLimit(newValue)
                        }
                    }
                }
                
                
                Section(header: Text("Privacy")) {
                    DisclosureGroup(isExpanded: $privacyExpanded) {
                        Text("Your calculation history remains 100% private, stored locally on your device. We only collect anonymous usage data to improve the app's performance and user experience.")
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
            .sheet(isPresented: $isShareSheetPresented) {
                ShareSheet(activityItems: [
                    "Check out Simple Voice Calculator - the easiest way to perform calculations using your voice!",
                    URL(string: "https://apps.apple.com/app/simple-voice-calculator/id6448565084")!
                ])
                .onDisappear {
                    // Reset the state when sheet is dismissed
                    isShareSheetPresented = false
                }
                .presentationDetents([.medium])
            }
        }
    }
    private func handleToggleChange(isOn: Bool) {
        if isOn {
            
            Mixpanel.mainInstance().track(event: "enabledTotalAnnouncement")
        } else {
            
            Mixpanel.mainInstance().track(event: "disabledTotalAnnouncement")
        }
    }
    
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}




#Preview { SettingsView()}
