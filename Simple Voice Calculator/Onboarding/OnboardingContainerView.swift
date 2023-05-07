//
//  OnboardingContainerView.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 5/1/23.
//

import SwiftUI

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

struct OnboardingContainerView: View {
    @State private var currentPage = 0
    
    var isActualIntro: Bool
    private var indexedFeatures: [IndexedFeature] {
        features.enumerated().map { index, feature in
            IndexedFeature(index: index, feature: feature)
        }
    }
    
    var body: some View {
        TabView(selection: $currentPage){
            ForEach(indexedFeatures) { indexedFeature in
                OnboardingContentView(feature: indexedFeature.feature, currentPage: $currentPage, actualIntro: isActualIntro, featureIndex: indexedFeature.index)
                    .tag(indexedFeature.index)
            }
        }.tabViewStyle(PageTabViewStyle())
            .edgesIgnoringSafeArea(.all)
    }
}

