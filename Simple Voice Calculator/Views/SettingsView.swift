import SwiftUI
import Mixpanel
import SuperwallKit

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var helpExpanded = false
    @State private var privacyExpanded = false
    private let productIdentifiers = ["CoffeeTip1", "CoffeeTip5", "CoffeeTip10",
                                      "pro_monthly", "pro_yearly",
                                      "pro_monthly_discounted", "pro_yearly_discounted"]
    
    @AppStorage("shouldSpeakTotal") var shouldSpeakTotal: Bool = false
    
    @EnvironmentObject var historyManager: HistoryManager
    
    //CloudKit
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var syncStatusMessage: String = ""
    @State private var showSyncStatus: Bool = false
    
    // History limit options for Pro users
    private let historyLimitOptions = [25, 50, 100]
    @AppStorage("historyLimit") var historyLimit: Int = 25
    
    @State private var isShareSheetPresented = false
    
    @ObservedObject var storeManager = StoreManager.shared
    @State private var introCoverShowing: Bool = false
    @State private var versionNumber: String = Bundle.main.releaseVersionNumber ?? "1.0"
    
    private var isRegUser: Bool {
        return StoreManager.shared.isRegUser
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Quick Help")) {
                    
                    NavigationLink(destination: FAQView())
                    {
                        HStack (alignment: .center) {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.accentColor)
                            Text("FAQ")
                        }
                    }.accessibilityLabel("About Simple Voice Calculator")
                    
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
                            Text("🎙️")
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
                    
                    if isRegUser {
                        Button(action: {
                            Superwall.shared.register(placement: "campaign_trigger", feature: {
                                // Called when purchase is successful
                                
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ProSubscriptionPurchased"),
                                    object: nil,
                                    userInfo: ["isNewPurchase": true]
                                )
                                
                                // Launch task to check subscription status
                                Task {
                                    await StoreManager.shared.checkSubscriptionStatus()
                                }
                            })
                            
                        }) {
                            HStack {
                                Text("💎")
                                    .foregroundColor(.accentColor)
                                Text("Upgrade to PRO")
                                
                            }
                        }
                        .accessibilityLabel("Upgrade to Pro")
                    }
                    if !isRegUser {                        // Show Pro Badge for premium users
                        HStack {
                            Text("💎")
                                .foregroundColor(.accentColor)
                            Text("Your current mode is")
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
                        
                        if let expirationDateString = storeManager.formatExpirationDate() {
                            Text(expirationDateString)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
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
                        HStack (alignment: .center) {
                            Image(systemName: "speaker.wave.2.bubble")
                                .foregroundColor(.accentColor)
                            Text("Announce Total")
                            
                        }
                    }
                    .tint(.blue)
                    .onChange(of: shouldSpeakTotal, perform: handleToggleChange)
                    
                    // History Limit Picker for Pro users
                    if !isRegUser {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Picker("History Limit", selection: $historyLimit) {
                                    ForEach(historyLimitOptions, id: \.self) { limit in
                                        Text("\(limit) equations").tag(limit)
                                    }
                                }
                                .onChange(of: historyLimit) { newValue in
                                    historyManager.updateHistoryLimit(newValue)
                                }
                            }
                        }
                        
                        //CloudKit
                        HStack {
                            Image(systemName: "icloud")
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading) {
                                Text("Sync Across Devices")
                                
                                if let lastSyncDate = cloudKitManager.lastSyncDate {
                                    Text("Last synced: \(formattedDate(lastSyncDate))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if cloudKitManager.isSyncing {
                                ProgressView()
                                    .padding(.horizontal)
                            } else {
                                Button(action: {
                                    // Perform manual sync
                                    Task {
                                        // Check if iCloud is available
                                        if await cloudKitManager.checkAccountStatus() {
                                            // Trigger sync in history and favorites managers
                                            historyManager.performManualSync()
                                            // Get reference to favorites manager
                                            let favoritesManager = FavoritesManager()
                                            favoritesManager.performManualSync()
                                            
                                            syncStatusMessage = "Sync complete"
                                        } else {
                                            syncStatusMessage = "Unable to sync. Please check your internet connection and try again when online."
                                        }
                                        showSyncStatus = true
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(.accentColor)
                                }
                                .disabled(cloudKitManager.isSyncing)
                            }
                        }
                        .alert(isPresented: $showSyncStatus) {
                            Alert(title: Text("Sync Status"), message: Text(syncStatusMessage), dismissButton: .default(Text("OK")))
                        }
                        
                        
                    }
                    
                }
                
                
                Section(header: Text("Privacy")) {
                    DisclosureGroup(isExpanded: $privacyExpanded) {
                        Text("Your calculation history remains 100% private, stored locally and on Apple iCloud servers. We only collect anonymous usage data to improve the app's performance and user experience.")
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
                Button("Restore Purchases") {
                    storeManager.restorePurchases()
                }
                .font(.footnote)
                .foregroundColor(.blue)
                
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
                // Check subscription status on appear and update UI
                Task {
                    await storeManager.checkSubscriptionStatus()
                    
                    //CloudKit - don't sync when opening settings right now, maybe later enable but annoying
                    //                    if await cloudKitManager.shouldSync() {
                    //                        historyManager.checkAndPerformSync()
                    //                    }
                }
                
                // Refresh store products (ensures prices are up to date)
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
                
                let shareMessage = NSLocalizedString(
                    "Check out Simple Voice Calculator - the easiest way to perform calculations using your voice!",
                    comment: "Text content for sharing the app"
                )
                ShareSheet(activityItems: [
                    shareMessage,
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
    
    // Helper function to format date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
