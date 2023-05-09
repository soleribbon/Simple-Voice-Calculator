import SwiftUI
import Speech

struct CalculatorView: View {
    @State private var textFieldValue = ""
    @State private var isRecording = false
    @State private var previousText = ""
    @State private var audioEngine = AVAudioEngine()
    
    let supportedLanguages = ["en-US", "de-DE", "es-ES", "es-MX", "it-IT"]
    @State var currentLanguage = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    @State private var speechRecognizer: SFSpeechRecognizer!
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var selectedComponentIndex: Int?
    @State private var scrollID = UUID()
    @State private var totalValue: String = ""
    @State private var isSettingsModalPresented = false
    @State private var scale: CGFloat = 1.0
    @State private var recordScale: CGFloat = 1.0
    
    @StateObject private var permissionChecker = PermissionChecker()
    @FocusState private var isTextFieldFocused: Bool
    
    
    @State var recordLink: Bool = false
    @State var inputLink: Bool = false
    
    //haptics
    let impactLight = UIImpactFeedbackGenerator(style: .light)
    let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    let impactRecord = UIImpactFeedbackGenerator(style: .medium)
    
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text("Simple Voice Calculator")
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: {
                    impactSoft.impactOccurred()
                    isSettingsModalPresented = true
                    
                }, label: {
                    Image(systemName: "gear.badge.questionmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                    
                })
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
                                                    Label("Edit", systemImage: "pencil")
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
                                    
                                ).background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(red: 0.882, green: 0.882, blue: 0.882)) // #e1e1e1)
                                        .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.01)), radius:5, x:0, y:3)
                                )
                                .padding(.horizontal)
                            }
                            
                            
                            
                            
                            
                        }
                        
                    }
                    
                }
                
            } label: {
                Text("Equation Components")
                    .opacity(0.3)
                
            }
            .padding(.horizontal)
            
            Group {
                TextField("Enter equation", text: $textFieldValue)
                    .focused($isTextFieldFocused)
                    .customTextFieldStyle(isRecording: isRecording)
                    .onChange(of: textFieldValue) { newValue in
                        textFieldValue = getEquationComponents().joined(separator: "")
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
                    
                    Button(action: {
                        impactLight.impactOccurred()
                        insertText(")")
                    }) {
                        Text(")")
                            .padding(.horizontal, 10)
                            .ActionButtons(isRecording: isRecording, bgColor: Color(white: 0.235))
                        
                    }
                    
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
                        })
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
                
                
                Button(action: {
                    impactRecord.impactOccurred()
                    
                    
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.4, blendDuration: 0.5)) {
                        recordScale = 1.1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.4, blendDuration: 0.5)) {
                            recordScale = 1.0
                        }
                    }
                    
                    if isRecording {
                        stopRecording(completion: {})//add completion handler if necessary
                    } else {
                        startRecording()
                    }
                }) {
                    Label(isRecording ? "Stop Talking" : "Start Talking", systemImage: isRecording ? "waveform" : "mic.fill")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color.red : Color.blue)
                        .cornerRadius(10)
                }.scaleEffect(recordScale)
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
            
            if (currentLanguage == "de-US"){
                currentLanguage = "de-DE"
            }else if (currentLanguage == "it-US"){
                currentLanguage = "it-IT"
            }else if (currentLanguage == "es-US"){
                currentLanguage = "es-ES"
            }else if (currentLanguage == "mx-US"){
                currentLanguage = "es-MX"
            }
            
            
            
            speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: supportedLanguages.contains(currentLanguage) ? currentLanguage : "en-US"))
            
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
        }
        print("Active: \(components)")
        return components
    }
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        previousText = textFieldValue
        
        isRecording = true
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
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
                
                //                let convertedText = convertWordsToNumbers(transcribedText)
                textFieldValue = previousText + transcribedText            }
            
            if error != nil {
                audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                recognitionRequest.endAudio()
                self.recognitionRequest = nil
                recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            fatalError("Could not start the audio engine: \(error)")
        }
    }
    private func stopRecording(completion: @escaping () -> Void) {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        textFieldValue = getEquationComponents().joined(separator: "")
        
        recognitionRequest?.endAudio()
        
        isRecording = false
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
        let components = getEquationComponents()
        print(components)
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
            
            print("Cleaned Component: \(filteredComponent)")
            
            cleanedComponents.append(filteredComponent)
            
        }
        
        let cleanedExpression = cleanedComponents.joined(separator: "")
        //remove these specific operators from start & end if needed
        let trimmedExpression = cleanedExpression.trimmingCharacters(in: CharacterSet(charactersIn: "+*/"))
        print("Cleaned Expression: \(trimmedExpression)")
        
        
        
        let expression = NSExpression(format: trimmedExpression)
        
        if let result = expression.expressionValue(with: nil, context: nil) as? NSNumber {
            totalValue = result.stringValue
        } else {
            totalValue = "Error"
        }
        
    }
    
}

