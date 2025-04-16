//
//  EquationComponentsView.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 27/03/25.
//

import SwiftUI

struct EquationComponentsView: View {
    let components: [String]
    let onEdit: (Int) -> Void
    let onDelete: (Int) -> Void
    @Binding var scale: CGFloat
    let isRecording: Bool
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(components.indices, id: \.self) { index in
                    let component = components[index]
                    let symbolColor = getSymbolColor(component: component)
                    
                    HStack {
                        Spacer()
                        Menu {
                            if !isRecording {
                                Section {
                                    Button(action: {
                                        onEdit(index)
                                    }) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                }
                            }
                            Section {
                                Button(role: .destructive, action: {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.5)) {
                                        scale = 1.15
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.5)) {
                                            scale = 1.0
                                        }
                                    }
                                    onDelete(index)
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        } label: {
                            Text(component)
                                .bold()
                                .foregroundColor(symbolColor?.foreground ?? .black)
                                .padding()
                                .accessibilityLabel(component)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(symbolColor?.strokeColor ?? .clear, lineWidth: 2)
                                )
                                .background(
                                    Rectangle()
                                        .fill(symbolColor?.background ?? Color.white)
                                        .cornerRadius(10)
                                        .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)), radius: 4, x: 0, y: 2)
                                )
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
                                .scaleEffect(scale)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
