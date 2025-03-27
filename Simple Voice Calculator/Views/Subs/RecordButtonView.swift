//
//  EquationComponentsView.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne
//

import SwiftUI

/// A view that behaves more like a classic UIKit button:
/// - Shrinks immediately on touch down (finger press)
/// - Fires `action` on lift up (finger release)
/// - No extra SwiftUI highlighting or delays
struct RecordButton<Label: View>: View {
    let action: () -> Void
    let label: () -> Label
    
    // Tracks if the user is currently pressing
    @GestureState private var isPressed = false
    let impactRecord = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        // Press down (onChanged) and release (onEnded).
        let pressGesture = DragGesture(minimumDistance: 0)
            .updating($isPressed) { _, state, _ in
                // The moment the finger goes down, set isPressed = true
                state = true
            }
            .onEnded { _ in
                // Fire the action on release
                impactRecord.impactOccurred()
                action()
            }
        
        return label()
        // Shrink while isPressed = true
            .scaleEffect(isPressed ? 0.90 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
            .gesture(pressGesture)
    }
}
