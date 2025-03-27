//
//  Functions.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 4/25/23.
//

import SwiftUI
import Speech
import StoreKit
import Sentry

func replaceNumberWords(_ component: String) -> String {
    
    //for transforming word inputs
    let numberWordMapping: [String: String] = [
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
        "and": ""
    ]
    
    var modifiedComponent = component
    for (word, number) in numberWordMapping {
        
        if modifiedComponent.contains(word) {
            print("Found: \(word) in \(modifiedComponent) - deleted/replaced")
            
            modifiedComponent = modifiedComponent.replacingOccurrences(of: word, with: number)
        }
    }
    return modifiedComponent
}


// Function to parse equation text into components
func parseEquationComponents(from textFieldValue: String) -> [String] {
    let equation = textFieldValue.lowercased()
    var components = [String]()
    var currentComponent = ""
    var isInsideBracket = false
    var previousComponentWasSymbol = false

    let characters = Array(equation)

    for i in 0..<characters.count {
        let char = characters[i]
        var modifiedChar = char

        // SOME FILTERS
        if char == "/" {
            modifiedChar = "÷"
        }
        if char == "x" {
            modifiedChar = "×"
        }
        if modifiedChar == "(" {
            isInsideBracket = true
        }
        if modifiedChar == ")" {
            isInsideBracket = false
        }
        if modifiedChar == "=" || modifiedChar == "," {
            continue
        }

        // Insert missing multiplication sign
        if i < characters.count - 1 {
            let nextChar = characters[i + 1]
            if (char.isNumber && nextChar == "(") || (char == ")" && nextChar.isNumber) {
                currentComponent.append(modifiedChar)
                components.append(currentComponent.filter { !$0.isWhitespace })
                components.append("×")
                currentComponent = ""
                continue
            }
        }

        if isInsideBracket || !"+-÷×/*".contains(modifiedChar) {
            currentComponent.append(modifiedChar)
        } else {
            if !currentComponent.isEmpty {
                if previousComponentWasSymbol {
                    components[components.count - 1].append(contentsOf: currentComponent.filter { !$0.isWhitespace })
                } else {
                    components.append(currentComponent.filter { !$0.isWhitespace })
                }
                currentComponent = ""
            }
            previousComponentWasSymbol = true
            components.append(String(modifiedChar))
        }
    }

    if !currentComponent.isEmpty {
        let replacedComponent = replaceNumberWords(currentComponent.filter { !$0.isWhitespace })
        let modifiedComponent = processPercentSigns(in: replacedComponent)

        if previousComponentWasSymbol {
            components[components.count - 1].append(contentsOf: modifiedComponent)
        } else {
            components.append(modifiedComponent)
        }
    }

    //removing first characters if they are invalid (in real time)
    if let first = components.first, let firstChar = first.first, ["×", "÷", "+", "%"].contains(firstChar) {
        components[0] = String(first.dropFirst())
    }

    return components
}

// Function to prepare an expression for evaluation
func prepareExpressionForEvaluation(components: [String]) -> String {
    var cleanedComponents: [String] = []

    let allowedCharacters = CharacterSet(charactersIn: "0123456789.+-÷*×/()%")

    for component in components {
        //Filtering out some bad bits
        let cleanedComponent = component
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: " ", with: "")

        // Remove unwanted characters
        let filteredComponent = cleanedComponent.components(separatedBy: allowedCharacters.inverted).joined()

        let doubleComponent = filteredComponent

        cleanedComponents.append(doubleComponent)
    }

    let cleanedExpression = cleanedComponents
        .joined(separator: "")
        .replacingOccurrences(of: "/", with: "*1.0/")
        .trimmingCharacters(in: CharacterSet(charactersIn: "+*/"))

    //remove these specific operators from start & end if needed
    let trimmedExpression = cleanedExpression.trimmingCharacters(in: CharacterSet(charactersIn: "+*/"))

    return trimmedExpression
}

// Function to format calculation result
func formatCalculationResult(result: NSNumber) -> String {
    if floor(result.doubleValue) == result.doubleValue {
        // If the result is an integer, just convert to Int and then to String.
        return "\(Int(result.doubleValue))"
    } else {
        // Otherwise, limit the number of decimal places to 3.
        return String(format: "%.3f", result.doubleValue)
    }
}

func getSymbolColor(component: String) -> (foreground: Color, background: Color, strokeColor: Color)? {
    if component.starts(with: "+") {
        return (foreground: .green, background: Color.green.opacity(0.1), strokeColor: Color.green.opacity(0.3))
    } else if component.starts(with: "-") {
        return (foreground: .red, background: Color.red.opacity(0.1),strokeColor: Color.red.opacity(0.3))
    } else if component.starts(with: "×") {
        return (foreground: .blue, background: Color.blue.opacity(0.1),strokeColor: Color.blue.opacity(0.3))
    } else if component.starts(with: "÷") {
        return (foreground: .orange, background: Color.yellow.opacity(0.1),strokeColor: Color.yellow.opacity(0.3))
    } else {
        return nil
    }
}




func isValidExpression(_ expression: String) -> Bool {
    if expression.isEmpty {
        return false
    }
    
    // Check if the first character is a percent sign
    if expression.first == "%" {
        return false
    }
    let allowedCharacters = CharacterSet(charactersIn: "0123456789.+-÷*×/(),%")
    let unwantedCharacters = expression.unicodeScalars.filter { !allowedCharacters.contains($0) }
    
    if !unwantedCharacters.isEmpty {
        return false
    }
    var openParenthesesCount = 0
    var closeParenthesesCount = 0
    
    for i in 0..<expression.count {
        let char = expression[expression.index(expression.startIndex, offsetBy: i)]
        if char == "(" {
            openParenthesesCount += 1
        } else if char == ")" {
            closeParenthesesCount += 1
        }
        
        if i < expression.count - 1 {
            let nextChar = expression[expression.index(expression.startIndex, offsetBy: i + 1)]
            
            if "+-÷*×/%".contains(char) && "+-÷*×/%".contains(nextChar) {
                return false
            }
            
            if "(".contains(char) && ")".contains(nextChar){
                return false
            }
            
            if "+-÷*×/".contains(char) && nextChar == ")" {
                return false
            }
        }
    }
    
    if openParenthesesCount != closeParenthesesCount {
        return false
    }
    
    if let lastChar = expression.last, "+-÷*×/(.".contains(lastChar) {
        return false
    }
    
    return true
}



struct actionButtons: ViewModifier {
    var isRecording: Bool
    var bgColor: Color
    
    func body(content: Content) -> some View {
        content
            .bold()
            .padding()
            .background(bgColor)
            .cornerRadius(10)
            .foregroundColor(.white)
            .opacity(isRecording ? 0.4 : 1)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
        
    }
}




extension View {
    func ActionButtons(isRecording: Bool, bgColor: Color) -> some View {
        self.modifier(actionButtons(isRecording: isRecording, bgColor: bgColor))
    }
}


struct CustomTextFieldModifier: ViewModifier {
    var isRecording: Bool
    
    func body(content: Content) -> some View {
        content
            .padding()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .autocapitalization(.none)
            .keyboardType(.numbersAndPunctuation)
            .multilineTextAlignment(.leading)
            .submitLabel(.done)
            .font(.title2)
            .opacity(isRecording ? 0.6 : 1)
    }
}

extension View {
    func customTextFieldStyle(isRecording: Bool) -> some View {
        self.modifier(CustomTextFieldModifier(isRecording: isRecording))
    }
}

extension View {
    func hideKeyboard() {
        let resign = #selector(UIResponder.resignFirstResponder)
        UIApplication.shared.sendAction(resign, to: nil, from: nil, for: nil)
    }
}



class PermissionChecker: ObservableObject {
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    func checkPermissions() {
        SFSpeechRecognizer.requestAuthorization { (status) in
            if status != .authorized {
                self.alertTitle = "Speech Recognition Denied"
                self.alertMessage = "Please restart and try again."
                DispatchQueue.main.async {
                    self.showAlert = true
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { (allowed) in
            if !allowed {
                self.alertTitle = "Microphone Access Denied"
                self.alertMessage = "This app requires access to your microphone. Please enable microphone access for this app in \nSettings > Privacy > Microphone"
                DispatchQueue.main.async {
                    self.showAlert = true
                }
            }
        }
    }
}








class PurchaseModel: ObservableObject {
    let productIdentifiers = ["CoffeeTip1", "CoffeeTip5", "CoffeeTip10"]
    
    @Published var products: [Product] = []
    
    func fetchProducts() async {
        
        
        Task.init(priority: .background){
            do {
                let products = try await Product.products(for: productIdentifiers)
                DispatchQueue.main.async {
                    self.products = products
                    print(products)
                }
            }
            catch {
                print(error)
                SentrySDK.capture(message: "Error getting ProductIdentifiers/Products")
            }
            
        }
        
    }
    
    func purchase() {
        
        Task.init(priority: .background){
            guard let product = products.first else { return }
            do {
                let result = try await product.purchase()
                print(result)
            }
            catch {
                print(error)
            }
            
        }
        
        
        
    }
}


func processPercentSigns(in component: String) -> String {
    var result = component
    let regexPattern = "([0-9.]+)%"
    
    do {
        let regex = try NSRegularExpression(pattern: regexPattern, options: [])
        let matches = regex.matches(in: component, options: [], range: NSRange(location: 0, length: component.count))
        
        for match in matches.reversed() {
            let percentValueRange = match.range(at: 1)
            let percentValue = NSString(string: component).substring(with: percentValueRange)
            if let number = Double(percentValue) {
                let newValue = number / 100
                result = (result as NSString).replacingCharacters(in: match.range, with: String(newValue))
            }
        }
    } catch {
        print("Error processing percent signs: \(error.localizedDescription)")
        SentrySDK.capture(message: "Error processing percent signs")
    }
    
    return result
}

//let conversionTable: [String: String] = [
//    "plus": "+",
//    "minus": "-",
//    "times": "×",
//    "multiplied": "×",
//    "divide": "÷",
//    "divided": "÷",
//    "equal": "=",
//    "point": ".",
//    "zero": "0",
//    "one": "1",
//    "two": "2",
//    "three": "3",
//    "four": "4",
//    "for": "4",
//    "five": "5",
//    "six": "6",
//    "sex": "6",
//    "seven": "7",
//    "eight": "8",
//    "ate": "8",
//    "nine": "9",
//    "ten": "10",
//    "0": "0",
//    "1": "1",
//    "2": "2",
//    "3": "3",
//    "4": "4",
//    "5": "5",
//    "6": "6",
//    "7": "7",
//    "8": "8",
//    "9": "9",
//    "10":"10",
//    "+": "+",
//    "-": "-",
//    "/": "/",
//    "=": "=",
//    ".": ".",
//    "(": "(",
//    ")": ")"
//
//]
