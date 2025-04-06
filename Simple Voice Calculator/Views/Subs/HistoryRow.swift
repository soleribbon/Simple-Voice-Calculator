//
//  HistoryRow.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 01/04/25.
//

import SwiftUI

// Simple button style for menu items
struct HighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct HistoryRow: View {
    var equation: String
    var result: String
    var onAction: (HistoryMode) -> Void
    
    @State private var isPressed = false
    
    var isFirstRow: Bool = false //tracking for new featureTip interaction
    
    @Namespace private var animationNamespace
    
    var body: some View {
        Menu {
            Section(header: Text("Insert into Current Equation")) {
                // Replace option
                Button {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    onAction(.replace)
                } label: {
                    Label("Replace", systemImage: "rectangle.2.swap")
                }
                
                // Add option
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAction(.add)
                } label: {
                    Label("Add", systemImage: "plus")
                }
                
                // Subtract option
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAction(.subtract)
                } label: {
                    Label("Subtract", systemImage: "minus")
                }
                
                // Multiply option
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAction(.multiply)
                } label: {
                    Label("Multiply", systemImage: "multiply")
                }
                
                // Divide option
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onAction(.divide)
                } label: {
                    Label("Divide", systemImage: "divide")
                }
            }
        } label: {
            HStack {
                Text(equation)
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.3)
                
                Spacer()
                
                HStack {
                    Text("=")
                        .foregroundColor(.primary)
                        .font(.subheadline)
                        .opacity(0.3)
                    Text(result)
                        .foregroundColor(.primary)
                        .font(.body)
                        .bold()
                }
                .padding(.vertical)
                .padding(.leading)
            }
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(isPressed ? 0.05 : 0))
                    .matchedGeometryEffect(id: "background", in: animationNamespace)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .if(isFirstRow) { view in
            view.featureTip(.historyRow)
        }
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    //                    UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                    
                    
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6).delay(0.2)) {
                        isPressed = false
                    }
                }
        )
        .buttonStyle(HighlightButtonStyle())
        .transaction { transaction in
            transaction.animation = .spring(response: 0.2, dampingFraction: 0.6)
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.tertiarySystemBackground))
                .padding(
                    EdgeInsets(
                        top: 4,
                        leading: 0,
                        bottom: 4,
                        trailing: 0
                    )
                )
        )
        .id(equation + result) // Unique identifier for each row
        .onAppear{
            FeatureTipsManager.shared.markFeatureAsSeen(.historyRow)
        }
    }
}
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
