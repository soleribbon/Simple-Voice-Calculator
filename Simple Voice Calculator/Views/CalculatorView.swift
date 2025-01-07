import SwiftUI
import Speech
import JavaScriptCore
import Sentry

struct CalculatorView: View {
    
    
    @State private var textFieldValue = ""
    @State private var isRecording = false
    @State private var previousText = ""
    @State private var audioEngine = AVAudioEngine()
    
    let supportedLanguages = ["en-US", "de-DE", "es-ES", "es-MX", "it-IT", "ko-KR", "hi-IN"]
    @State var currentLanguage = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    @State private var speechRecognizer: SFSpeechRecognizer!
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var selectedComponentIndex: Int?
    @State private var scrollID = UUID()
    @State private var totalValue: String = ""
    @State private var isSettingsModalPresented = false
    @State private var scale: CGFloat = 1.0
    @State private var recordScale: CGFloat = 1.0
    
    @AppStorage("shouldSpeakTotal") var shouldSpeakTotal: Bool = false
    
    @StateObject private var permissionChecker = PermissionChecker()
    @FocusState private var isTextFieldFocused: Bool
    
    
    @State var recordLink: Bool = false
    @State var inputLink: Bool = false
    
    //haptics
    let impactLight = UIImpactFeedbackGenerator(style: .light)
    let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    let impactRecord = UIImpactFeedbackGenerator(style: .medium)
    let impactTotal = UIImpactFeedbackGenerator(style: .heavy)
    
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("Simple Voice Calculator")
                    .font(.title2)
                    .bold()
                    .accessibilityLabel("Simple Voice Calculator")
                Spacer()
                Button(action: {
                    impactSoft.impactOccurred()
                    isSettingsModalPresented = true
                    
                }, label: {
                    Image(systemName: "gear.badge.questionmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                }).accessibilityLabel("Settings")
            }.padding(.horizontal)
            
            GroupBox {
                GeometryReader { geo in
                    ScrollViewReader { scrollViewProxy in
                        ScrollView(.vertical) {
                            VStack(alignment: .trailing, spacing: 4) {
                                
                                //main component styling
                                ForEach(getEquationComponents().indices, id: \.self) { index in
                                    
                                    let component = getEquationComponents()[index]
                                    let symbolColor = getSymbolColor(component: component)
                                    
                                    HStack {
                                        Spacer()
                                        Menu {
                                            Section {
                                                Button(action: {
                                                    
                                                    impactLight.impactOccurred()
                                                    selectedComponentIndex = index
                                                    selectComponentInTextField()
                                                    
                                                    
                                                }) {
                                                    Label("Edit", systemImage: "pencil").accessibilityLabel("Edit")
                                                }
                                            }
                                            Section {
                                                Button(role: .destructive, action: {
                                                    impactLight.impactOccurred()
                                                    selectedComponentIndex = index
                                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.5)) {
                                                        scale = 1.15
                                                    }
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.5)) {
                                                            scale = 1.0
                                                        }
                                                    }
                                                    deleteComponent(at: index)
                                                    
                                                    
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
                                }//end of FOR EACH
                                
                            }.id(scrollID) //useless for now
                            
                        }//end of Scrollview
                        .onChange(of: getEquationComponents().count) { _ in
                            
                            withAnimation {
                                let lastIndex = getEquationComponents().indices.last
                                if let last = lastIndex {
                                    scrollViewProxy.scrollTo(last, anchor: .bottom)
                                }
                            }
                        }
                        if !isTextFieldFocused{
                            VStack {
                                HStack (alignment: .center){
                                    Text("TOTAL:")
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .opacity(0.5)
                                    Spacer()
                                    Text("=")
                                        .foregroundColor(.black)
                                        .accessibilityLabel("=")
                                        .opacity(0.3)
                                    Text(totalValue)
                                        .font(.system(.headline, design: .monospaced))
                                        .bold()
                                        .foregroundColor(.black)
                                    
                                }
                                .padding()
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(Color(red: 0.839, green: 0.839, blue: 0.839), lineWidth: 2)
                                        .accessibilityLabel("TOTAL: \(totalValue)")
                                    
                                    
                                    
                                ).background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(red: 0.882, green: 0.882, blue: 0.882)) // #e1e1e1)
                                    
                                )
                                .padding(.horizontal)
                            }
                            .onTapGesture {
                                if shouldSpeakTotal && !totalValue.isEmpty && totalValue != "Invalid Equation" {
                                    impactTotal.impactOccurred()
                                    speakTotal(totalValue)
                                }
                            }
                            
                        }
                        
                    }
                    
                }
                
            } label: {
                Text("Equation Components")
                    .accessibilityLabel("Equation Components")
                    .opacity(0.3)
                
            }
            .padding(.horizontal)
            
            Group {
                TextField("Enter equation", text: $textFieldValue)
                    .accessibilityLabel("Enter equation")
                    .focused($isTextFieldFocused)
                    .customTextFieldStyle(isRecording: isRecording)
                    .onChange(of: textFieldValue) { newValue in
                        textFieldValue = getEquationComponents().joined(separator: "") // COMMENT FOR TESTING
                        if isValidExpression(newValue) {
                            calculateTotalValue()
                        } else {
                            print("NOT Valid: \(newValue)")
                            if textFieldValue == ""{
                                totalValue = ""
                                
                            }else{
                                totalValue = "Invalid Equation"
                            }
                        }
                    }
                HStack {
                    Button(action: {
                        impactLight.impactOccurred()
                        insertText("(")
                    }) {
                        Text("(")
                            .padding(.horizontal, 10)
                            .ActionButtons(isRecording: isRecording, bgColor: Color(white: 0.235))
                    }
                    .accessibilityLabel("(")
                    
                    
                    Button(action: {
                        impactLight.impactOccurred()
                        insertText(")")
                    }) {
                        Text(")")
                            .padding(.horizontal, 10)
                            .ActionButtons(isRecording: isRecording, bgColor: Color(white: 0.235))
                        
                    }
                    .accessibilityLabel(")")
                    
                    
                    Menu {
                        Button(action: {
                            impactLight.impactOccurred()
                            insertText("+")
                        }, label: {
                            Label("+ Insert", systemImage: "plus")
                        })
                        
                        Button(action: {
                            impactLight.impactOccurred()
                            insertText("-")
                        }, label: {
                            Label("- Insert", systemImage: "minus")
                            
                            
                        }).accessibilityLabel("Minus Insert")
                        Button(action: {
                            impactLight.impactOccurred()
                            insertText("×")
                        }, label: {
                            Label("× Insert", systemImage: "multiply")
                        })
                        Button(action: {
                            impactLight.impactOccurred()
                            insertText("÷")
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
                        clearTextField()
                        
                    }) {
                        Text("Clear")
                            .ActionButtons(isRecording: isRecording, bgColor: Color.orange)
                            .opacity(textFieldValue.isEmpty ? 0.4 : 1)
                        
                    }
                    .disabled(textFieldValue.isEmpty)
                }
                
            }
            .disabled(isRecording)
            .padding(.horizontal)
            
            HStack {
                RecordButton(action: {
                    if isRecording {
                        stopRecording(completion: {}) //COMMENT FOR TESTING
                        
                    } else {
                        startRecording() //COMMENT FOR TESTING
                        //FOR TESTING
                        //testExpressionEvaluation()
                    }
                }) {
                    Label(isRecording ? "Stop Talking" : "Start Talking", systemImage: isRecording ? "waveform" : "mic.fill")
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
            
        }
        .onOpenURL { url in
            // Handle this deep link URL
            handleWidgetDeepLink(url)
        }
        //        .onOpenURL(perform: { (url) in
        //                        self.recordLink = url == URL(string: "calculator:///recordLink")!
        //                        self.inputLink = url == URL(string: "calculator:///inputLink")!
        //         })
        
        .onTapGesture {
            hideKeyboard()
        }
        
        .sheet(isPresented: $isSettingsModalPresented, content: {
            SettingsView()
        })
        .onAppear(perform: {
            //            print(SFSpeechRecognizer.supportedLocales())
            permissionChecker.checkPermissions()
            
            
            //TRANSLATING SYSTEM LANGUAGE TO SF SPEECH LANGUAGE
            let languageMappings: [String: String] = [
                "de-US": "de-DE",
                "it-US": "it-IT",
                "es-US": "es-ES",
                "mx-US": "es-MX",
                "ko-US": "ko-KR",
                "hi-US": "hi-IN"
            ]
            
            if let mappedLanguage = languageMappings[currentLanguage] {
                currentLanguage = mappedLanguage
            }
            
            if !supportedLanguages.contains(currentLanguage) {
                currentLanguage = "en-US"
            }
            
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
            print("Current Language: \(currentLanguage)")
            
            //configuring playback from main speaker, not just top one
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            } catch {
                print("Failed to set audio session category or override output port: \(error)")
                SentrySDK.capture(message: "Error setting up audio to play from main speaker")
            }
            
            
            print(currentLanguage)
            
            
        })
        .alert(isPresented: $permissionChecker.showAlert) {
            Alert(
                title: Text(permissionChecker.alertTitle),
                message: Text(permissionChecker.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        
    } //end body
    
    
    func handleWidgetDeepLink(_ url: URL) {
        
        if url.absoluteString == "calculator:///recordLink"{
            startRecording()
        }else{
            //FOCUS ON TEXTFIELD
            if let windowScene = getWindowScene(),
               let textField = findTextField(in: windowScene.windows.first!) {
                textField.becomeFirstResponder()
            }
            
        }
    }
    
    func deleteComponent(at index: Int) {
        var components = getEquationComponents()
        if components.indices.contains(index) {
            components.remove(at: index)
            textFieldValue = components.joined(separator: "")
            if isValidExpression(textFieldValue) {
                calculateTotalValue()
            } else {
                print("NOT Valid: \(textFieldValue)")
                if textFieldValue == ""{
                    totalValue = ""
                    
                }else{
                    totalValue = "Invalid Equation"
                }
            }
        }
    }
    
    
    private func findTextField(in view: UIView) -> UITextField? {
        for subview in view.subviews {
            if let textField = subview as? UITextField {
                return textField
            }
            if let found = findTextField(in: subview) {
                return found
            }
        }
        return nil
    }
    
    private func getWindowScene() -> UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive && $0 is UIWindowScene } as? UIWindowScene
    }
    
    private func selectComponentInTextField() {
        guard let index = selectedComponentIndex else { return }
        let components = getEquationComponents()
        guard index < components.count else { return }
        
        let selectedComponent = components[index]
        
        var position = 0
        
        // Iterate through the components before the selected one
        for i in 0..<index {
            // Add the length of each component to the position
            position += components[i].count
        }
        
        // Find the TextField in the app's window
        if let windowScene = getWindowScene(),
           let textField = findTextField(in: windowScene.windows.first!) {
            // Make the TextField the first responder (give it focus)
            textField.becomeFirstResponder()
            
            // Calculate the start and end positions of the selected component in the TextField
            if let startPosition = textField.position(from: textField.beginningOfDocument, offset: position),
               let endPosition = textField.position(from: startPosition, offset: selectedComponent.count) {
                textField.selectedTextRange = textField.textRange(from: startPosition, to: endPosition)
            }
        }
    }
    
    
    
    func speakTotal(_ total: String) {
        let languageCode = currentLanguage
        let totalString = String(format: NSLocalizedString("Total equals %@", comment: ""), total)
        let utterance = AVSpeechUtterance(string: totalString)
        
        if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        } else {
            // Log the issue and use default voice
            SentrySDK.capture(message: "Invalid language code: \(languageCode). Falling back to default voice.")
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        DispatchQueue.main.async {
            speechSynthesizer.speak(utterance)
        }
    }
    
    
    func getEquationComponents() -> [String] {
        let inputValue = textFieldValue
        let equation = inputValue.lowercased()
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
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        //        print("Active: \(components)")
        return components
    }
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Stop any ongoing speech playback
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        previousText = textFieldValue
        
        DispatchQueue.main.async {
            isRecording = true
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            SentrySDK.capture(message: "SFSpeechAudioBufferRecognitionRequest error")
            
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest")
        }
        
        let inputNode = audioEngine.inputNode
        
        if(inputNode.inputFormat(forBus: 0).channelCount == 0){
            NSLog("Not enough available inputs!")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString.replacingOccurrences(of: " ", with: "")
                DispatchQueue.main.async {
                    textFieldValue = previousText + transcribedText
                }
            }
            
            if error != nil {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                recognitionRequest.endAudio()
                self.recognitionRequest = nil
                recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.inputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            SentrySDK.capture(message: "Audio engine start error")
            fatalError("Could not start the audio engine: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping () -> Void) {
        
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionTask = nil
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioEngine.reset() //just for good measure
        DispatchQueue.main.async {
            isRecording = false
            textFieldValue = getEquationComponents().joined(separator: "")//moved from 3rd to last in the list - revert if necessary
            //speak out total
            if shouldSpeakTotal && !totalValue.isEmpty && totalValue != "Invalid Equation" {
                speakTotal(totalValue)
            }
        }
        completion()
    }
    
    private func clearTextField() {
        textFieldValue = ""
        previousText = ""
    }
    private func updateTextFieldValue() {
        guard let windowScene = getWindowScene(),
              let textField = findTextField(in: windowScene.windows.first!) else { return }
        textFieldValue = textField.text ?? ""
    }
    
    private func insertText(_ text: String) {
        guard let windowScene = getWindowScene(),
              let textField = findTextField(in: windowScene.windows.first!) else { return }
        
        // If the cursor is at the start of the text field, move it to the end.
        if let startPosition = textField.selectedTextRange?.start, startPosition == textField.beginningOfDocument {
            textField.selectedTextRange = textField.textRange(from: textField.endOfDocument, to: textField.endOfDocument)
        }
        
        // Save cursor position
        let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: textField.selectedTextRange!.start) + text.count
        
        // Insert the given text at the current cursor position.
        textField.replace(textField.selectedTextRange!, withText: text)
        
        // Restore cursor position
        if let newPosition = textField.position(from: textField.beginningOfDocument, offset: cursorPosition) {
            textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
        }
        
        // Update textFieldValue manually
        textFieldValue = textField.text ?? ""
    }
    
    
    private func calculateTotalValue() {
        DispatchQueue.global(qos: .userInitiated).async { //COMMENT FOR TESTING
            
            let components = getEquationComponents()
            //        print(components)
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
                
                //print("Cleaned Component: \(filteredComponent)")
                
                //            let doubleComponent = (filteredComponent.rangeOfCharacter(from: CharacterSet(charactersIn: ".+-*/")) == nil) ? filteredComponent + ".0" : filteredComponent
                
                let doubleComponent = filteredComponent
                
                
                
                cleanedComponents.append(doubleComponent)
                
                //cleanedComponents.append(filteredComponent)
                
            }
            
            let cleanedExpression = cleanedComponents
                .joined(separator: "")
                .replacingOccurrences(of: "/", with: "*1.0/")
                .trimmingCharacters(in: CharacterSet(charactersIn: "+*/"))
            
            
            //remove these specific operators from start & end if needed
            let trimmedExpression = cleanedExpression.trimmingCharacters(in: CharacterSet(charactersIn: "+*/"))
            //        print("Cleaned Expression: \(trimmedExpression)")
            
            DispatchQueue.main.async { //COMMENT FOR TESTING
                
                if let result = ExpressionSolver.solveExpression(trimmedExpression) {
                    
                    if floor(result.doubleValue) == result.doubleValue {
                        // If the result is an integer, just convert to Int and then to String.
                        totalValue = "\(Int(result.doubleValue))"
                        
                    }
                    else {
                        // Otherwise, limit the number of decimal places to 3.
                        totalValue = String(format: "%.3f", result.doubleValue)
                        
                    }
                    
                } else {
                    totalValue = "Invalid Equation"
                }
            }
        }
    }
    
    func testExpressionEvaluationIOS() {
        let testCases = [
            ("(6+5)/2", "5.500"),
            ("11/2", "5.500"),
            ("1+2", "3"),
            ("3-1", "2"),
            ("(4+5)*2", "18"),
            ("(6/3)+(2*3)", "8"),
            ("((3+2)-1)*(4/2)", "8"),
            ("4/75", "0.053"),
            ("(7+3)*(4+2)/3", "20"), // Multiple Parentheses
            ("9/(3+1)-2", "0.250"),     // Parentheses and Post-DivisionSubtraction
            ("12.5+7.5", "20"),     // Decimal Addition
            ("(4*2.5)+(1.5*2)", "13"), // Multiple Decimal Multiplication
            ("(3.6+1.4)/5", "1"),   // Decimal Addition and Division
            ("5+((1+2)*4)-3", "14"),    // Nested Parentheses
            ("0.5*4+2", "4"),       // Decimal Multiplication and Addition
            ("6/3/2", "1"),         // Sequential Division
            ("10-(8/4)", "8"),      // Parentheses Implied
            ("10/10/10", "0.100"),
            ("100/(2+3)", "20"),
            ("(((4+2)*3)-6)/2", "6"),
            ("(5+5)*(3+(2*2))", "70"),
            ("((3+2)*4)/(5+5)", "2"),
            ("(6*3)/2+((4+2)/2)", "12"),
            ("(((3*2)+(2*2))/(2+2))+3", "5.500"),
            ("(15-3)*(2+3)", "60"),
            ("(10/5)*((2+3)*2)", "20"),
            ("(4*(2+(2*2)))/(4+4)", "3"),
            ("(20/4)+(3*2)-(2*2)", "7"),
            ("2+2*2", "6"),
            ("(3+(4+5))", "12"),
            ("(10*(2+3))-((4+3)x2)", "36"),
            ("(3+2)x(4*2)/2-3", "17"),
            ("(((4+5)x2)-1)/3", "5.667"),
            ("(8/4)x(3+(2+1))", "12"),
            ("(10-2)/(2x2)", "2"),
            ("(2+(3x2))/(4x2)", "1"),
            ("(2+3)x(4+(5x6))/2", "85"),
            ("(4x(2+3))/(4+(5-3))", "3.333"),
            ("(5+(3x4))/(2+3)", "3.400"),
            ("(2+2)x(2+2)", "16"),
            
        ]
        
        for (expression, expected) in testCases {
            textFieldValue = expression
            
            calculateTotalValue()
            
            if totalValue == expected {
                print("✔️ passed for expression \(expression)")
            } else {
                print("❌ FAILED for expression \(expression). Got \(totalValue), expected \(expected)")
            }
        }
    }
}


