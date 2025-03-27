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
    
    static let wordReplacements: [String: String] = [
        "zero": "0",
        "one": "1",
        "two": "2",
        "three": "3",
        "four": "4",
        "five": "5",
        "six": "6",
        "seven": "7",
        "eight": "8",
        "nine": "9",
        "million": "000000",
        "minus": "-",
        "plus": "+",
        "times": "×",
        "time": "×",
        "multiplyby": "×",
        "multipliedby": "×",
        "dividedby": "÷",
        "divideby": "÷"
    ]
    
    func getEquationComponents(_ equation: String) -> [String] {
        let operatorSet = CharacterSet(charactersIn: "+-×÷*/")
        var components: [String] = []
        var currentComponent = ""
        
        // Remove commas from the equation
        var sanitizedEquation = equation.replacingOccurrences(of: ",", with: "")
        
        // Filter words like "minus seven" to "-7", etc.
        for (key, value) in CalculatorLogic.wordReplacements {
            sanitizedEquation = sanitizedEquation.lowercased()
            sanitizedEquation = sanitizedEquation.replacingOccurrences(of: key.lowercased(), with: value).replacingOccurrences(of: " ", with: "")
        }
        
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
        
        // Combine splitting logic with the initial iteration
        var finalComponents: [String] = []
        var tempComponent = ""
        for component in components {
            for char in component {
                if operatorSet.contains(char.unicodeScalars.first!) {
                    if !tempComponent.isEmpty {
                        finalComponents.append(tempComponent)
                    }
                    tempComponent = String(char) // Start a new component with the operator
                } else {
                    tempComponent.append(char) // Continue building the number
                }
            }
            if !tempComponent.isEmpty {
                finalComponents.append(tempComponent)
                tempComponent = "" // Reset tempComponent for the next iteration
            }
        }
        
        return finalComponents
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
