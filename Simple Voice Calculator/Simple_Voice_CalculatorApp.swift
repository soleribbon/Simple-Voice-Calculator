//
//  Simple_Voice_CalculatorApp.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 4/22/23.
//

import SwiftUI

@main
struct Simple_Voice_CalculatorApp: App {
    @AppStorage("isOnboarding") var isOnboarding = true
    var body: some Scene {
        
        
        WindowGroup {
            if isOnboarding {
                OnboardingContainerView(isActualIntro: true)
            } else {
                CalculatorView()
//                    .environment(\.locale, .init(identifier: "hi"))

                
            }
        }
    }
}
