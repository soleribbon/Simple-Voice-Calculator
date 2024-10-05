//
//  CalculatorModel.swift
//  Simple Voice Calculator Watch Edition Watch App
//
//  Created by Ravi Heyne on 30/09/24.
//

import Foundation
import Combine

class CalculatorModel: ObservableObject {
    @Published var equationComponents: [String] = []
    @Published var totalValue: String = "0"
    // Any other shared properties if needed
}
