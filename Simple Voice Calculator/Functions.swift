//
//  Functions.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 4/25/23.
//

import SwiftUI
import Speech

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

    let allowedCharacters = CharacterSet(charactersIn: "0123456789.+-÷*×/(),")
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
            
            if "+-÷*×/".contains(char) && "+-÷*×/".contains(nextChar) {
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
            .fontWeight(.bold)
            .padding()
            .background(bgColor)
            .cornerRadius(10)
            .foregroundColor(.white)
            .opacity(isRecording ? 0.4 : 1)
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
