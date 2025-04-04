import SwiftUI
import Speech
import JavaScriptCore
import Sentry

struct CalculatorView: View {
    @StateObject private var historyManager = HistoryManager()
    @Environment(\.scenePhase) private var scenePhase
    
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
    @State private var isHistoryModalPresented = false
    @State private var scale: CGFloat = 1.0
    @State private var recordScale: CGFloat = 1.0
    
    //FOR TESTING
    @StateObject private var testMode = TestMode()
    @State private var testTimer: Timer? = nil
    
    @State private var isProcessingText = false
    
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
            // App Header
            HStack {
                Text("Simple Voice Calculator")
                    .font(.title2)
                    .bold()
                    .accessibilityLabel("Simple Voice Calculator")
                Spacer()
                
                Button(action: {
                    impactSoft.impactOccurred()
                    runTests()
                }) {
                    Image(systemName: testMode.testingInProgress ? "checkmark.seal.fill" : "checkmark.seal")
                        .font(.title2)
                        .foregroundColor(testMode.testingInProgress ? .green : .primary)
                }
                .accessibilityLabel("Run Tests")
                
                Button(action: {
                    impactSoft.impactOccurred()
                    
                    if historyManager.isRegUser && historyManager.historyViewCount >= 3 {
                        // Show paywall modal or alert
                        showPaywallAlert()
                    } else {
                        // Increment view count
                        historyManager.incrementHistoryViewCount()
                        isHistoryModalPresented = true
                    }
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        // Notification badge
                        if historyManager.showHistoryBadge {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .offset(x: 3, y: -3)
                        }
                    }
                }
                .accessibilityLabel("History")
                
                Button(action: {
                    impactSoft.impactOccurred()
                    isSettingsModalPresented = true
                }) {
                    Image(systemName: "gear.badge.questionmark")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal)
            
            // Equation Components Group
            GroupBox {
                GeometryReader { _ in
                    ScrollViewReader { scrollViewProxy in
                        EquationComponentsView(
                            components: getEquationComponents(),
                            onEdit: { index in
                                impactLight.impactOccurred()
                                selectedComponentIndex = index
                                selectComponentInTextField()
                            },
                            onDelete: { index in
                                impactLight.impactOccurred()
                                selectedComponentIndex = index
                                deleteComponent(at: index)
                            },
                            scale: $scale
                        )
                        .onChange(of: getEquationComponents().count) { _ in
                            withAnimation {
                                let lastIndex = getEquationComponents().indices.last
                                if let last = lastIndex {
                                    scrollViewProxy.scrollTo(last, anchor: .bottom)
                                }
                            }
                        }
                        
                        if !isTextFieldFocused {
                            TotalDisplayView(
                                totalValue: totalValue,
                                onTap: {
                                    if shouldSpeakTotal && !totalValue.isEmpty && totalValue != "Invalid Equation" {
                                        impactTotal.impactOccurred()
                                        speakTotal(totalValue)
                                    }
                                }
                            )
                        }
                    }
                }
            } label: {
                Text("Equation Components")
                    .accessibilityLabel("Equation Components")
                    .opacity(0.3)
            }
            .padding(.horizontal)
            
            // Input Section
            CalculatorInputView(
                textFieldValue: $textFieldValue,
                isRecording: isRecording,
                impactLight: impactLight,
                onInsertText: insertText,
                onClear: clearTextField,
                onFocusChanged: { isFocused in
                    // Track focus state changes in the main view
                    isTextFieldFocused = isFocused
                }
            )
            .onChange(of: textFieldValue) { newValue in
                // Avoid reprocessing when text is being programmatically updated
                guard !isProcessingText else { return }
                isProcessingText = true
                
                // Process on background thread
                DispatchQueue.global(qos: .userInteractive).async {
                    let components = getEquationComponents()
                    let joined = components.joined(separator: "")
                    let isValid = isValidExpression(newValue)
                    
                    DispatchQueue.main.async {
                        textFieldValue = joined
                        if isValid {
                            calculateTotalValue()
                        } else {
                            totalValue = textFieldValue.isEmpty ? "" : "Invalid Equation"
                        }
                        isProcessingText = false
                    }
                }
            }
            .padding(.horizontal)
            
            
            
            // Recording Button
            HStack {
                RecordButton(action: {
                    if isRecording {
                        stopRecording(completion: {})
                    } else {
                        startRecording()
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
            handleWidgetDeepLink(url)
        }
        .onTapGesture {
            hideKeyboard()
        }
        .sheet(isPresented: $isSettingsModalPresented) {
            SettingsView()
        }
        .sheet(isPresented: $isHistoryModalPresented) {
            HistoryView(
                onEquationSelected: { equation in
                    textFieldValue = equation
                    calculateTotalValue()
                },
                onEquationOperation: { historyResult, operation in
                    if !textFieldValue.isEmpty && operation != "" {
                        textFieldValue = "(\(textFieldValue))\(operation)(\(historyResult))"
                        calculateTotalValue()
                    } else {
                        if operation == "-" && textFieldValue.isEmpty {
                            textFieldValue = "-\(historyResult)"
                        } else {
                            textFieldValue = historyResult
                        }
                        calculateTotalValue()
                    }
                }
            )
            .environmentObject(historyManager)
        }
        .onAppear {
            setupAudioAndSpeech()
        }
        .alert(isPresented: $permissionChecker.showAlert) {
            Alert(
                title: Text(permissionChecker.alertTitle),
                message: Text(permissionChecker.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            historyManager.saveCurrentEquationToHistory()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                historyManager.saveCurrentEquationToHistory()
            }
        }
    }
    
    func showPaywallAlert() {
        let alert = UIAlertController(
            title: "Premium Feature",
            message: "The History feature is available with the premium subscription. Would you like to upgrade now?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Subscribe", style: .default) { _ in
            // Handle subscription process
            // You can launch your in-app purchase flow here
        })
        
        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel))
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    // Setup audio and speech on app appear
    private func setupAudioAndSpeech() {
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
        
        //configuring playback from main speaker, not just top one
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if isRecording || shouldSpeakTotal {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.mixWithOthers])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            }
        } catch {
            print("Failed to set audio session category or override output port: \(error)")
            SentrySDK.capture(message: "Error setting up audio to play from main speaker")
        }
    }
    
    // Wrapper for getEquationComponents function to make code cleaner
    func getEquationComponents() -> [String] {
        return parseEquationComponents(from: textFieldValue)
    }
}
extension CalculatorView {
    
    func runTests() {
        // Already running tests
        if testMode.testingInProgress {
            return
        }
        
        // Reset and start tests
        testMode.startTesting()
        
        // Cancel any existing timer
        testTimer?.invalidate()
        
        // Create a new timer that fires every 0.3 seconds
        testTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [self] _ in
            if let currentTest = testMode.currentTest {
                // Set the text field to the current test input
                textFieldValue = currentTest.input
                
                // Force calculation
                calculateTotalValue()
                
                // Quick delay to ensure calculation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Record the test result
                    testMode.recordTestResult(input: currentTest.input, output: totalValue)
                    
                    // Move to the next test
                    testMode.moveToNextTest()
                    
                    // If all tests are complete, stop the timer and print results
                    if testMode.testsFinished {
                        self.testTimer?.invalidate()
                        self.testTimer = nil
                        
                        // Print test results to console
                        print("Tests completed: \(testMode.passedCount) passed, \(testMode.failedCount) failed")
                        for test in testMode.testCases {
                            if !test.passed {
                                print("Failed: \(test.input) → Expected: \(test.expectedOutput), Got: \(test.actualOutput)")
                            }
                        }
                        
                        // Clear the calculator for normal use
                        textFieldValue = ""
                        totalValue = ""
                    }
                }
            } else {
                // No more tests, stop the timer
                testTimer?.invalidate()
                testTimer = nil
            }
        }
    }
    
    func handleWidgetDeepLink(_ url: URL) {
        if url.absoluteString == "calculator:///recordLink"{
            startRecording()
        } else {
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
                if textFieldValue == ""{
                    totalValue = ""
                }else{
                    totalValue = "Invalid Equation"
                }
            }
        }
    }
    
    func findTextField(in view: UIView) -> UITextField? {
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
    
    func getWindowScene() -> UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive && $0 is UIWindowScene } as? UIWindowScene
    }
    
    func selectComponentInTextField() {
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
    func processVoiceInput(_ input: String) -> String {
        // Define word-to-symbol mappings
        print(input)
        let wordMapping: [String: String] = [
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
            "plus": "+",
            "add": "+",
            "minus": "-",
            "subtract": "-",
            "times": "×",
            "time": "×",
            "multiply": "×",
            "multiply by": "×",
            "multiplied by": "×",
            "multipliedby": "×",
            "divide by": "÷",
            "divideby": "÷",
            "divide": "÷",
            "dividedby": "÷",
            "divided by": "÷",
            "over": "÷",
            "open bracket": "(",
            "close bracket": ")",
            "opening bracket": "(",
            "closing bracket": ")",
            "left bracket": "(",
            "right bracket": ")",
            "open parenthesis": "(",
            "close parenthesis": ")",
            "percent": "%",
            "equals": "="
        ]
        
        // Process the input text
        var processedInput = input.lowercased()
        
        // Apply word replacements
        for (word, symbol) in wordMapping {
            processedInput = processedInput.replacingOccurrences(of: word, with: symbol)
        }
        
        // Remove spaces
        processedInput = processedInput.replacingOccurrences(of: " ", with: "")
        
        return processedInput
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
                    let processedText = self.processVoiceInput(transcribedText)
                    textFieldValue = previousText + processedText
                    //                    textFieldValue = previousText + transcribedText
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
            textFieldValue = getEquationComponents().joined(separator: "")
            //speak out total
            if shouldSpeakTotal && !totalValue.isEmpty && totalValue != "Invalid Equation" {
                speakTotal(totalValue)
            }
        }
        completion()
    }
    
    func clearTextField() {
        if totalValue != "Invalid Equation" {
            historyManager.saveCurrentEquationToHistory()
        }
        textFieldValue = ""
        previousText = ""
    }
    
    func updateTextFieldValue() {
        guard let windowScene = getWindowScene(),
              let textField = findTextField(in: windowScene.windows.first!) else { return }
        textFieldValue = textField.text ?? ""
    }
    
    private func insertText(_ text: String) {
        
        // Check if trying to add an invalid symbol at the start of an empty equation
        if textFieldValue.isEmpty && ["×", "÷", "+", "%"].contains(text) {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            // Don't add the character
            return
        }
        
        //Make sure we're on the main thread
        DispatchQueue.main.async {
            guard let windowScene = getWindowScene(),
                  let textField = findTextField(in: windowScene.windows.first!) else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.performTextInsertion(textField: textField, text: text)
            }
        }
    }
    
    // New helper method to handle the actual insertion
    private func performTextInsertion(textField: UITextField, text: String) {
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
    
    func calculateTotalValue() {
        DispatchQueue.global(qos: .userInitiated).async {
            let components = getEquationComponents()
            let trimmedExpression = prepareExpressionForEvaluation(components: components)
            
            DispatchQueue.main.async {
                if let result = ExpressionSolver.solveExpression(trimmedExpression) {
                    totalValue = formatCalculationResult(result: result)
                    
                    // Only save valid equations to history
                    if !textFieldValue.isEmpty && totalValue != "Invalid Equation" {
                        historyManager.updateCurrentEquation(equation: textFieldValue, result: totalValue)
                    }
                } else {
                    totalValue = "Invalid Equation"
                }
            }
        }
    }
}
