//
//  ContentView.swift
//  Simple Voice Calculator Watch Edition Watch App
//
//  Created by Ravi Heyne on 30/09/24.
//

// ContentView.swift
// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var calculatorModel = CalculatorModel()
    @State private var selection = 1 // Start at the middle tab (CalculatorView)
    
    var body: some View {
        TabView(selection: $selection) {
            // Left View: Clear Equation
            ClearEquationView(calculatorModel: calculatorModel, selection: $selection)
                .tag(0)
            
            // Middle View: Calculator
            CalculatorView(calculatorModel: calculatorModel)
                .tag(1)
            
            // Right View: Settings
            SettingsWrapperView()
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
    }
}

struct SettingsWrapperView: View {
    var body: some View {
        NavigationView {
            SettingsView()
        }
    }
}

