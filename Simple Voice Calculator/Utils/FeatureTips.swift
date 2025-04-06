//
//  FeatureTips.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 06/04/25.
//

import SwiftUI
import Foundation

// Conditionally import TipKit
#if canImport(TipKit) && swift(>=5.9)
import TipKit
#endif

// MARK: - Feature Identifier Enum
enum FeatureId: String, CaseIterable {
    case history = "feature_history"
    case historyRow = "feature_history_row"
    // Add more features here in the future
}

// MARK: - Feature Info Struct
struct FeatureInfo {
    let id: FeatureId
    let title: String
    let message: String
    let iconName: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(id: FeatureId, title: String, message: String, iconName: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.iconName = iconName
        self.actionTitle = actionTitle
        self.action = action
    }
}

// MARK: - Feature Tips Manager
class FeatureTipsManager: ObservableObject {
    static let shared = FeatureTipsManager()
    
    // Notification for opening features from tips
    static let openFeatureNotification = Notification.Name("openFeatureFromTip")
    
    // Storage for seen features
    @Published private var seenFeatures: Set<String> = []
    
    // Feature definitions
    private var featureInfos: [FeatureId: FeatureInfo] = [:]
    
    private init() {
        // Load previously viewed features from UserDefaults
        if let savedFeatureIds = UserDefaults.standard.stringArray(forKey: "seenFeatures") {
            seenFeatures = Set(savedFeatureIds)
        }
    }
    
    // MARK: - Public API
    
    /// Register a feature to be highlighted to users
    func registerFeature(id: FeatureId, title: String, message: String, iconName: String,
                         actionTitle: String? = nil, action: (() -> Void)? = nil) {
        let info = FeatureInfo(
            id: id,
            title: title,
            message: message,
            iconName: iconName,
            actionTitle: actionTitle,
            action: action
        )
        featureInfos[id] = info
    }
    
    /// Check if a specific feature should be highlighted
    func shouldShowTip(for featureId: FeatureId) -> Bool {
        return !seenFeatures.contains(featureId.rawValue)
    }
    
    /// Get feature info, if available
    func getFeatureInfo(for featureId: FeatureId) -> FeatureInfo? {
        return featureInfos[featureId]
    }
    
    /// Mark a feature as seen/used
    func markFeatureAsSeen(_ featureId: FeatureId) {
        seenFeatures.insert(featureId.rawValue)
        saveSeenFeatures()
    }
    
    /// Reset a specific feature tip to show again
    func resetFeatureTip(_ featureId: FeatureId) {
        seenFeatures.remove(featureId.rawValue)
        saveSeenFeatures()
        
#if canImport(TipKit) && swift(>=5.9)
        if #available(iOS 17.0, *) {
            Task {
                try? Tips.resetDatastore()
            }
        }
#endif
    }
    
    /// Reset all feature tips
    func resetAllFeatureTips() {
        seenFeatures.removeAll()
        saveSeenFeatures()
        
#if canImport(TipKit) && swift(>=5.9)
        if #available(iOS 17.0, *) {
            Task {
                try? Tips.resetDatastore()
            }
        }
#endif
    }
    
    // MARK: - Private Helpers
    
    private func saveSeenFeatures() {
        UserDefaults.standard.set(Array(seenFeatures), forKey: "seenFeatures")
    }
    
    // MARK: - iOS 17+ TipKit Integration
    
    func configure() async {
#if canImport(TipKit) && swift(>=5.9)
        if #available(iOS 17.0, *) {
            do {
                try Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            } catch {
                print("Failed to configure TipKit: \(error)")
            }
        }
#endif
    }
}


// MARK: - View Extensions for iOS 17+ support
extension View {
    /// Apply a feature tip only if it hasn’t been seen
    func featureTip(_ featureId: FeatureId) -> AnyView {
    #if canImport(TipKit) && swift(>=5.9)
        if #available(iOS 17.0, *) {
            if FeatureTipsManager.shared.shouldShowTip(for: featureId) {
                return AnyView(TipKitViewModifier(featureId: featureId).modify(self))
            } else {
                return AnyView(self)
            }
        } else {
            return AnyView(self)
        }
    #else
        return AnyView(self)
    #endif
    }
}


#if canImport(TipKit) && swift(>=5.9)
@available(iOS 17.0, *)
struct HistoryFeatureTipDefinition: Tip {
    var title: Text {
        Text("History Now Available")
    }
    
    var message: Text? {
        Text("Track and reuse your past calculations!")
    }
    
    var image: Image? {
        Image(systemName: "clock.arrow.circlepath")
    }
    
}

@available(iOS 17.0, *)
struct HistoryRowTipDefinition: Tip {
    var title: Text {
        Text("Tap Any Row for More Options")
    }
    
    var message: Text? {
        Text("You can replace your current equation or perform math operations with history items.")
    }
    
    var image: Image? {
        Image(systemName: "hand.tap")
    }
}

// Update the TipKitViewModifier to handle the new tip type
@available(iOS 17.0, *)
struct TipKitViewModifier {
    let featureId: FeatureId
    
    func modify<T: View>(_ content: T) -> some View {
        // Use AnyView to wrap different return types
        switch featureId {
        case .history:
            let tip = HistoryFeatureTipDefinition()
            return AnyView(content.popoverTip(tip))
        case .historyRow:
            let tip = HistoryRowTipDefinition()
            return AnyView(content.popoverTip(tip))
        }
    }
}
#endif
