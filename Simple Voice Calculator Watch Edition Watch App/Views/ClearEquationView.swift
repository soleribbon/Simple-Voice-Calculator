//
//  ClearEquationView.swift
//  Simple Voice Calculator Watch Edition Watch App
//
//  Created by Ravi Heyne on 30/09/24.
//

import SwiftUI
import WatchKit

struct ClearEquationView: View {
    @ObservedObject var calculatorModel: CalculatorModel
    @Binding var selection: Int
    
    var body: some View {
        VStack {
            Text("Clear Equation")
                .font(.headline)
                .padding()
            Spacer()
            Button(action: {
                WKInterfaceDevice.current().play(.click)
                if !calculatorModel.equationComponents.isEmpty {
                    showClearConfirmationAlert()
                }else{
                    selection = 1
                }
                
            }) {
                Image(systemName: "trash.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.red)
                    .padding()
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Clear Equation")
            Spacer()
        }
    }
    
    func showClearConfirmationAlert() {
        WKInterfaceDevice.current().play(.click)
        
        WKExtension.shared().rootInterfaceController?.presentAlert(
            withTitle: "Clear Equation?",
            message: "This will erase your current equation.",
            preferredStyle: .actionSheet,
            actions: [
                WKAlertAction(title: "Clear", style: .destructive, handler: {
                    clearEquation()
                }),
                WKAlertAction(title: "Cancel", style: .cancel, handler: {})
            ]
        )
    }
    
    func clearEquation() {
        WKInterfaceDevice.current().play(.start)
        saveEquation(calculatorModel.equationComponents.joined(separator: ""))
        calculatorModel.equationComponents = []
        calculatorModel.totalValue = "0"
        // Navigate back to CalculatorView
        selection = 1
    }
    
    func saveEquation(_ equation: String) {
        // Retrieve stored equations from UserDefaults
        var recentEquations = UserDefaults.standard.stringArray(forKey: "recentEquations") ?? []
        
        // Append the new equation
        recentEquations.append(equation)
        
        // Ensure we only store the last 3 equations
        if recentEquations.count > 3 {
            recentEquations.removeFirst()
        }
        
        // Save the updated array back to UserDefaults
        UserDefaults.standard.set(recentEquations, forKey: "recentEquations")
    }
}
