//
//  Simple_Voice_CalculatorApp.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 4/22/23.
//

import SwiftUI
import Sentry
import Mixpanel
import SuperwallKit

@main
struct Simple_Voice_CalculatorApp: App {
    init() {
        setupSentry()
        setupMixpanel()
        setupFeatureTips()
        setupSubscriptions()
        setupSuperwall()
    }
    @AppStorage("isOnboarding") var isOnboarding = true
    var body: some Scene {
        WindowGroup {
            if isOnboarding {
                OnboardingContainerView(isActualIntro: true)
                
            } else {
                CalculatorView()
                    .tint(Color("accentColor"))
                    .task {
                        // Configure TipKit in an async task
                        await FeatureTipsManager.shared.configure()
                        
                        // Uncomment for testing
                        // await TipManager.shared.resetTips()
                    }
                    .onOpenURL { url in
                        Superwall.shared.handleDeepLink(url) // previewing
                    }
                //.environment(\.locale, .init(identifier: "hi"))
            }
        }
    }
    
    private func setupSubscriptions() {
        // Initialize the StoreManager singleton
        let storeManager = StoreManager.shared
        
        // Start requesting products
        storeManager.startRequest(with: ["CoffeeTip1", "CoffeeTip5", "CoffeeTip10",
                                         "pro_monthly", "pro_yearly",
                                         "pro_monthly_discounted", "pro_yearly_discounted"])
    }
    
    private func setupSentry() {
        SentrySDK.start { options in
            options.dsn = "https://d0a92dbd3ff1cef3e4d5fb8b8c3e8ec8@o4507253468823552.ingest.us.sentry.io/4507253470330880"
            /*options.debug = true*/ // Uncomment for terminal debug prints
            
            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // Adds a screenshot to error events
            options.attachViewHierarchy = true // Adds the view hierarchy to error events
            // Currently under experimental options:
            options.sessionReplay.onErrorSampleRate = 0.1 //10% of errors
            options.sessionReplay.sessionSampleRate = 0.0
        }
        // Uncomment next line to test if Sentry is working
        // SentrySDK.capture(message: "This app uses Sentry! :)")
    }
    private func setupMixpanel() {
        Mixpanel.initialize(token: "b610cfbee5151bcf6894de086ca940b5", trackAutomaticEvents: false)
    }
    
    private func setupSuperwall(){
        Superwall.configure(apiKey: "pk_80f8e967c979a2f4b58126b719ef4a05f3a2f0456441cf9e")
    }
    
    private func setupFeatureTips() {
        // Register the history feature tip
        FeatureTipsManager.shared.registerFeature(
            id: .history,
            title: "History - now available",
            message: "Your calculation history is now available for quick access and reuse.",
            iconName: "clock.arrow.circlepath",
            action: {
                NotificationCenter.default.post(
                    name: FeatureTipsManager.openFeatureNotification,
                    object: FeatureId.history
                )
            }
        )
        FeatureTipsManager.shared.registerFeature(
            id: .historyRow,
            title: "Tap Any Row for More Options",
            message: "You can replace your current equation or perform math operations with history items.",
            iconName: "hand.tap",
            actionTitle: nil,
            action: nil
        )
    }
}
