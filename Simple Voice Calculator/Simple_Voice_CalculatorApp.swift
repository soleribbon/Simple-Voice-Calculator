//
//  Simple_Voice_CalculatorApp.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 4/22/23.
//

import SwiftUI
import Sentry
import Mixpanel

@main
struct Simple_Voice_CalculatorApp: App {
    init() {
        setupSentry()
        setupMixpanel()
    }
    @AppStorage("isOnboarding") var isOnboarding = true
    var body: some Scene {
        
        
        WindowGroup {
            if isOnboarding {
                OnboardingContainerView(isActualIntro: true)
                
            } else {
                CalculatorView()
                    .tint(Color("accentColor"))
                //.environment(\.locale, .init(identifier: "hi"))
            }
        }
    }
    
    
    private func setupSentry() {
        SentrySDK.start { options in
            options.dsn = "https://d0a92dbd3ff1cef3e4d5fb8b8c3e8ec8@o4507253468823552.ingest.us.sentry.io/4507253470330880"
            /*options.debug = true*/ // Uncomment for terminal debug prints
            
            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // Adds a screenshot to error events
            options.attachViewHierarchy = true // Adds the view hierarchy to error events
              // Currently under experimental options:
            options.experimental.sessionReplay.onErrorSampleRate = 0.1 //10% of errors
            options.experimental.sessionReplay.sessionSampleRate = 0.0
        }
        // Uncomment next line to test if Sentry is working
        // SentrySDK.capture(message: "This app uses Sentry! :)")
    }
    private func setupMixpanel() {
        Mixpanel.initialize(token: "b610cfbee5151bcf6894de086ca940b5", trackAutomaticEvents: false)
    }
}
