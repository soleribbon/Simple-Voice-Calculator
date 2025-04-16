//
//  OnboardingContainerView.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 5/1/23.
//

import SwiftUI

struct OnboardingContainerView: View {
    @State private var currentPage = 0
    
    var isActualIntro: Bool
    
    private var indexedFeatures: [IndexedFeature] {
        features.enumerated().map { index, feature in
            IndexedFeature(index: index, feature: feature)
        }
    }
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(indexedFeatures) { indexedFeature in
                OnboardingContentView(
                    feature: indexedFeature.feature,
                    currentPage: $currentPage,
                    actualIntro: isActualIntro,
                    featureIndex: indexedFeature.index
                )
                .tag(indexedFeature.index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            setupAccessibility()
        }
    }
    
    private func setupAccessibility() {
        // Post a notification to announce when the onboarding starts for VoiceOver users
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let message = "Welcome to Simple Voice Calculator onboarding. Swipe left to navigate through \(features.count) screens."
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}

struct IndexedFeature: Identifiable {
    let id: UUID
    let index: Int
    let feature: Feature
    
    init(index: Int, feature: Feature) {
        self.id = feature.id
        self.index = index
        self.feature = feature
    }
}
