//
//  CalculatorLogic.swift
//  Simple Voice Calculator Watch Edition Watch App
//
//  Created by Ravi Heyne on 07/09/24.
//

import Foundation
import SwiftUI
import MathParser


struct CalculatorLogic {


    func getEquationComponents(_ equation: String) -> [String] {
        let operatorSet = CharacterSet(charactersIn: "+-×÷*/")
        var components: [String] = []
        var currentComponent = ""

        // Remove commas from the equation
        let sanitizedEquation = equation.replacingOccurrences(of: ",", with: "")

        for (index, char) in sanitizedEquation.enumerated() {
            if operatorSet.contains(char.unicodeScalars.first!) {
                // Handle first operator, if it's '+' or '-'
                if index == 0 && (char == "+" || char == "-") {
                    currentComponent.append(char) // Start with the operator for negative or positive numbers
                    continue
                }
                if !currentComponent.isEmpty {
                    components.append(currentComponent)
                }
                currentComponent = String(char) // Start a new component with the operator
            } else {
                currentComponent.append(char) // Continue building the number
            }
        }

        if !currentComponent.isEmpty {
            components.append(currentComponent) // Append the last component
        }

        return components
    }


    func calculateTotal(equationComponents: [String]) -> String {
        guard !equationComponents.isEmpty else {
            return "" // or return "Invalid Equation" if you prefer
        }

        let equation = equationComponents.joined()

        do {
            let result = try equation.evaluate()

            if floor(result) == result {
                return String(format: "%.0f", result) // No decimal places for whole numbers
            } else {
                return String(format: "%.2f", result) // Keep two decimal places for non-integers
            }
        } catch let error as MathParserError {
            switch error.kind {
            case .emptyGroup:
                return "Empty Expression"
            case .unknownOperator:
                return "Invalid Operator"
            default:
                return "Invalid Equation"
            }
        } catch {
            // This catch-all clause handles any other errors
            return "Unknown Error"
        }
    }



    func getSymbolColor(component: String) -> (foreground: Color, background: Color) {
        let operatorSet = CharacterSet(charactersIn: "+-×÷*/")
        if let firstChar = component.first, operatorSet.contains(firstChar.unicodeScalars.first!) {
            switch firstChar {
            case "+":
                return (.green, Color.green.opacity(0.2))
            case "-":
                return (.red, Color.red.opacity(0.2))
            case "×", "*":
                return (.blue, Color.blue.opacity(0.2))
            case "÷", "/":
                return (.orange, Color.orange.opacity(0.2))
            default:
                return (.primary, Color.gray.opacity(0.1))
            }
        } else {
            return (.primary, Color.gray.opacity(0.1))
        }
    }
}
