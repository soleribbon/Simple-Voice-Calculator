//
//  CalculatorInputView.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 27/03/25.
//

import SwiftUI

struct CalculatorInputView: View {
    @Binding var textFieldValue: String
    let isRecording: Bool
    let impactLight: UIImpactFeedbackGenerator
    
    // Use internal focus state instead of trying to pass it in
    @FocusState private var internalFocusState: Bool
    
    var onInsertText: (String) -> Void
    var onClear: () -> Void
    var onFocusChanged: ((Bool) -> Void)? // Callback for when focus changes
    
    var body: some View {
        VStack {
            TextField("Enter equation", text: $textFieldValue)
                .accessibilityLabel("Enter equation")
                .focused($internalFocusState) // Use our internal focus state
                .customTextFieldStyle(isRecording: isRecording)
                .onChange(of: internalFocusState) { newValue in
                    // Use async to prevent blocking the main thread
                    DispatchQueue.main.async {
                        onFocusChanged?(newValue)
                    }
                }
            
            HStack {
                Button(action: {
                    impactLight.impactOccurred()
                    onInsertText("(")
                }) {
                    Text("(")
                        .padding(.horizontal, 10)
                        .ActionButtons(isRecording: isRecording, bgColor: Color(white: 0.235))
                }
                .accessibilityLabel("(")
                
                // Rest of your buttons...
                Button(action: {
                    impactLight.impactOccurred()
                    onInsertText(")")
                }) {
                    Text(")")
                        .padding(.horizontal, 10)
                        .ActionButtons(isRecording: isRecording, bgColor: Color(white: 0.235))
                }
                .accessibilityLabel(")")
                
                Menu {
                    Button(action: {
                        impactLight.impactOccurred()
                        onInsertText("+")
                    }, label: {
                        Label("+ Insert", systemImage: "plus")
                    })
                    
                    Button(action: {
                        impactLight.impactOccurred()
                        onInsertText("-")
                    }, label: {
                        Label("- Insert", systemImage: "minus")
                    }).accessibilityLabel("Minus Insert")
                    
                    Button(action: {
                        impactLight.impactOccurred()
                        onInsertText("×")
                    }, label: {
                        Label("× Insert", systemImage: "multiply")
                    })
                    
                    Button(action: {
                        impactLight.impactOccurred()
                        onInsertText("÷")
                    }, label: {
                        Label("÷ Insert", systemImage: "divide")
                    })
                } label: {
                    Button(action: {}, label: {
                        Text("Sym")
                            .ActionButtons(isRecording: isRecording, bgColor: Color(red: 0.608, green: 0.318, blue: 0.878))
                    })
                }
                
                Button(action: {
                    impactLight.impactOccurred()
                    onClear()
                }) {
                    Text("Clear")
                        .ActionButtons(isRecording: isRecording, bgColor: Color.orange)
                        .opacity(textFieldValue.isEmpty ? 0.4 : 1)
                }
                .disabled(textFieldValue.isEmpty)
            }
        }
        .disabled(isRecording)
    }
}
