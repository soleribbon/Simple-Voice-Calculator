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

    // Track deleted components by their content and sequence
    @State private var deletedComponentsMap = [String: Bool]()


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
    @State private var previousEquationLength: Int = 0
    @State private var previousComponents: [String] = []

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
                        // Mark history as viewed
                        historyManager.markHistoryAsViewed()
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
                .featureTip(.history)


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
                            scale: $scale,
                            isRecording: isRecording
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
                .environmentObject(historyManager)
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

            NotificationCenter.default.addObserver(
                forName: FeatureTipsManager.openFeatureNotification,
                object: nil,
                queue: .main
            ) { [self] notification in
                // Check if notification is for history feature
                if let featureId = notification.object as? FeatureId, featureId == .history {
                    // Open history view
                    historyManager.markHistoryAsViewed()
                    isHistoryModalPresented = true
                }
            }
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
        .onDisappear{
            cleanupAudioSession()
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
            // Launch in-app purchase flow here
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
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [
                    .mixWithOthers,
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .duckOthers,
                    //.defaultToSpeaker //add maybe?
                ])
                try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            }
        } catch {
            print("Failed to set audio session category or override output port: \(error)")
            SentrySDK.capture(message: "Error setting up audio to play from main speaker")
        }
    }
    private func cleanupAudioSession() {

        // Deactivate audio session when view disappears
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error deactivating audio session: \(error)")
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
            NSLocalizedString("zero", comment: ""): "0",
            NSLocalizedString("one", comment: ""): "1",
            NSLocalizedString("two", comment: ""): "2",
            NSLocalizedString("three", comment: ""): "3",
            NSLocalizedString("four", comment: ""): "4",
            NSLocalizedString("five", comment: ""): "5",
            NSLocalizedString("six", comment: ""): "6",
            NSLocalizedString("seven", comment: ""): "7",
            NSLocalizedString("eight", comment: ""): "8",
            NSLocalizedString("nine", comment: ""): "9",
            // Addition
            NSLocalizedString("plus", comment: ""): "+",
            NSLocalizedString("add", comment: ""): "+",
            // Subtraction
            NSLocalizedString("minus", comment: ""): "-",
            NSLocalizedString("subtract", comment: ""): "-",
            // Multiplication
            NSLocalizedString("times", comment: ""): "×",
            NSLocalizedString("multiply", comment: ""): "×",
            NSLocalizedString("multiply by", comment: ""): "×",
            NSLocalizedString("multiplied by", comment: ""): "×",
            NSLocalizedString("multipliedby", comment: ""): "×",
            // Division
            NSLocalizedString("divide by", comment: ""): "÷",
            NSLocalizedString("divideby", comment: ""): "÷",
            NSLocalizedString("divide", comment: ""): "÷",
            NSLocalizedString("dividedby", comment: ""): "÷",
            NSLocalizedString("divided by", comment: ""): "÷",
            NSLocalizedString("over", comment: ""): "÷",
            // Parentheses
            NSLocalizedString("open bracket", comment: ""): "(",
            NSLocalizedString("close bracket", comment: ""): ")",
            NSLocalizedString("opening bracket", comment: ""): "(",
            NSLocalizedString("closing bracket", comment: ""): ")",
            NSLocalizedString("left bracket", comment: ""): "(",
            NSLocalizedString("right bracket", comment: ""): ")",
            NSLocalizedString("open parenthesis", comment: ""): "(",
            NSLocalizedString("close parenthesis", comment: ""): ")",
            NSLocalizedString("percent", comment: ""): "%",
            NSLocalizedString("equals", comment: ""): "=",
            // Filter out command words so they don't appear in the equation
            NSLocalizedString("clear", comment: ""): "",
            NSLocalizedString("stop", comment: ""): "",
            NSLocalizedString("done", comment: ""): "",
            NSLocalizedString("finish", comment: ""): "",
            NSLocalizedString("end", comment: ""): "",
            NSLocalizedString("recording", comment: ""): "",
            NSLocalizedString("record", comment: ""): ""
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

        // Set max volume
        utterance.volume = 1.0

        // Adjust rate and pitch for clarity
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.pitchMultiplier = 1.1

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


        previousEquationLength = textFieldValue.count
        previousComponents = getEquationComponents()

        previousText = textFieldValue

        DispatchQueue.main.async {
            isRecording = true
        }
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            SentrySDK.capture(message: "SFSpeechAudioBufferRecognitionRequest error")
            DispatchQueue.main.async {
                self.isRecording = false
                self.permissionChecker.alertTitle = "Speech Recognition Error"
                self.permissionChecker.alertMessage = "Unable to create speech recognition request. Please try again."
                self.permissionChecker.showAlert = true
            }
            return
        }

        let inputNode = audioEngine.inputNode

        if(inputNode.inputFormat(forBus: 0).channelCount == 0){
            NSLog("Not enough available inputs!")
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                // Get the raw transcription with spaces preserved
                let rawTranscriptionWithSpaces = result.bestTranscription.formattedString


                // Check for clear command first, before any other processing
                let clearPattern = "\\bclear\\b"
                if rawTranscriptionWithSpaces.range(of: clearPattern, options: [.regularExpression, .caseInsensitive]) != nil {
                    // Clear the equation
                    DispatchQueue.main.async {
                        // Clear the text field
                        self.textFieldValue = ""
                        self.previousText = ""
                        self.deletedComponentsMap.removeAll()

                        // Stop recording after clearing
                        self.stopRecording(completion: {})
                    }
                    return
                }


                // Process for equation first, before checking for stop commands
                var processedEquation = self.processVoiceInput(rawTranscriptionWithSpaces)


                // Handle deleted components if there are any
                if !self.deletedComponentsMap.isEmpty {
                    // Start with the previous components for reference
                    let previousComponents = self.previousComponents

                    // Parse the current full transcription
                    let fullEquation = self.previousText + processedEquation
                    let combinedComponents = parseEquationComponents(from: fullEquation)

                    // Create a map of the absolute positions of each component for reference
                    var componentPositions = [Int]()
                    var currentPos = 0
                    for component in combinedComponents {
                        componentPositions.append(currentPos)
                        currentPos += component.count
                    }

                    // Filter components, being extra careful with operators
                    var filteredComponents = [String]()
                    let previousComponentsCount = previousComponents.count

                    for i in 0..<combinedComponents.count {
                        let component = combinedComponents[i]
                        let absPosition = componentPositions[i]

                        // Determine if this component was part of the previous recording
                        let isFromPreviousRecording = i < previousComponentsCount

                        // Need to be extra careful to check both position and value
                        let isOperator = ["+", "-", "×", "÷"].contains(where: { component.hasPrefix($0) })

                        // Check against our deletion tracking map with multiple strategies
                        let shouldSkip = self.deletedComponentsMap.keys.contains { key in
                            // 1. Exact position and content match
                            if key.hasPrefix("exact_\(absPosition)_\(component.count)_") && key.hasSuffix(component) {
                                return true
                            }

                            // 2. For operators, check specialized operator position tracking
                            if isOperator && key == "op_pos_\(i)_\(component)" {
                                return true
                            }

                            // 3. Index-based deletion for components from previous recording
                            if isFromPreviousRecording && key.hasPrefix("idx_\(i)_") && key.hasSuffix(component) {
                                return true
                            }

                            // 4. Context-based matching (surrounding components)
                            if key.hasPrefix("ctx_") {
                                let prevComp = i > 0 ? combinedComponents[i-1] : ""
                                let nextComp = i < combinedComponents.count - 1 ? combinedComponents[i+1] : ""
                                let contextKey = "ctx_\(prevComp)_\(component)_\(nextComp)"
                                return key == contextKey
                            }

                            // 5. Content-based matching for non-operators (safer)
                            if !isOperator && key == "num_\(component)" {
                                return true
                            }

                            // 6. Special rule: if deleted this operator at this position before
                            if isOperator && isFromPreviousRecording {
                                // Check if deleted this specific operator at this position
                                let opPosKey = "op_pos_\(i)_\(component)"
                                return self.deletedComponentsMap[opPosKey] == true
                            }

                            return false
                        }

                        if !shouldSkip {
                            filteredComponents.append(component)
                        } else {
                            print("Skipping component: '\(component)' at index \(i), position \(absPosition)")
                        }
                    }

                    // Reconstruct equation from filtered components
                    let filteredEquation = filteredComponents.joined()

                    // Extract just the new transcription part
                    if filteredEquation.hasPrefix(self.previousText) && filteredEquation.count >= self.previousText.count {
                        let startIndex = filteredEquation.index(filteredEquation.startIndex,
                                                                offsetBy: self.previousText.count)
                        processedEquation = String(filteredEquation[startIndex...])
                    } else {
                        // Fallback: use filtered equation directly
                        processedEquation = filteredEquation
                        self.previousText = ""  // Reset previous context
                    }
                }

                // Check for stop commands in the raw transcription (with spaces)
                let stopCommands = ["stop", "recording", "end", "finish", "done"]
                let containsStopCommand = stopCommands.contains { command in
                    // Look for whole words or phrases with word boundaries
                    let pattern = "\\b\(command)\\b"
                    return rawTranscriptionWithSpaces.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
                }

                var hasDetectedStopCommand = false
                var lastValidEquation = ""

                // If a valid equation, save it
                if isValidExpression(processedEquation) {
                    lastValidEquation = processedEquation
                }

                if containsStopCommand && !hasDetectedStopCommand {
                    // Set flag to avoid multiple stop actions
                    hasDetectedStopCommand = true

                    // Use the last valid equation processed
                    DispatchQueue.main.async {
                        // Update with the last valid equation before stopping
                        if !lastValidEquation.isEmpty {
                            self.textFieldValue = self.previousText + lastValidEquation
                        } else {
                            // Fall back to processing without the stop command
                            // Get the transcription before the stop command
                            var filteredTranscription = rawTranscriptionWithSpaces.lowercased()

                            // Find and remove all stop commands
                            for command in stopCommands {
                                let pattern = "\\b\(command)\\b"
                                if let range = filteredTranscription.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                                    filteredTranscription = String(filteredTranscription[..<range.lowerBound])
                                }
                            }

                            // Process this final transcription without the stop command
                            let finalProcessedText = self.processVoiceInput(filteredTranscription)

                            // Only update if it's a valid expression
                            if isValidExpression(finalProcessedText) {
                                self.textFieldValue = self.previousText + finalProcessedText
                            }
                        }

                        // Stop recording after updating the text field
                        self.stopRecording(completion: {})
                    }
                } else if !hasDetectedStopCommand {
                    // No stop command detected, update the UI with the processed equation
                    DispatchQueue.main.async {
                        self.textFieldValue = self.previousText + processedEquation
                    }
                }
            }

            if error != nil {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                recognitionRequest.endAudio()
                self.recognitionRequest = nil
                self.recognitionTask = nil
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
            // Proper error handling without crashing
            SentrySDK.capture(message: "Audio engine start error: \(error.localizedDescription)")
            print("Could not start the audio engine: \(error.localizedDescription)")

            // Cleanup
            audioEngine.inputNode.removeTap(onBus: 0)

            // Reset recognition components
            recognitionTask?.cancel()
            recognitionTask = nil
            self.recognitionRequest?.endAudio()
            self.recognitionRequest = nil

            // Update UI
            DispatchQueue.main.async {
                self.isRecording = false
                self.permissionChecker.alertTitle = "Recording Error"
                self.permissionChecker.alertMessage = "Unable to start recording. Please try again."
                self.permissionChecker.showAlert = true
            }
            return
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

            // Clear deletion tracking when done
            deletedComponentsMap.removeAll()

            // Check if text field has focus before setting cursor position
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let windowScene = self.getWindowScene(),
                   let textField = self.findTextField(in: windowScene.windows.first!),
                   textField.isFirstResponder {
                    // Only position cursor if the text field has focus
                    let endPosition = textField.endOfDocument
                    textField.selectedTextRange = textField.textRange(from: endPosition, to: endPosition)
                }

                // Speak total if needed
                if self.shouldSpeakTotal && !self.totalValue.isEmpty && self.totalValue != "Invalid Equation" {
                    self.speakTotal(self.totalValue)
                }
            }
        }
        completion()
    }


    func deleteComponent(at index: Int) {
        var components = getEquationComponents()
        if components.indices.contains(index) {
            // Track the deleted component if recording
            if isRecording {
                let deletedComponent = components[index]

                // Store both the component and its absolute position in the text
                var absolutePosition = 0
                for i in 0..<index {
                    absolutePosition += components[i].count
                }

                // 1. Store by exact position and content
                deletedComponentsMap["exact_\(absolutePosition)_\(deletedComponent.count)_\(deletedComponent)"] = true

                // 2. Store by relative index in the components array
                deletedComponentsMap["idx_\(index)_\(deletedComponent)"] = true

                // 3. Store by content with type marker (for operators vs numbers)
                var typePrefix = "num_"
                if ["+", "-", "×", "÷"].contains(where: { deletedComponent.hasPrefix($0) }) {
                    typePrefix = "op_"
                }
                deletedComponentsMap["\(typePrefix)\(deletedComponent)"] = true

                // 4. Context with surrounding components (more specific)
                let prevComponent = index > 0 ? components[index-1] : ""
                let nextComponent = index < components.count - 1 ? components[index+1] : ""
                deletedComponentsMap["ctx_\(prevComponent)_\(deletedComponent)_\(nextComponent)"] = true

                // 5. Special case for operators with position info
                if ["+", "-", "×", "÷"].contains(where: { deletedComponent.hasPrefix($0) }) {
                    deletedComponentsMap["op_pos_\(index)_\(deletedComponent)"] = true
                }


            }

            // Remove the component as usual
            components.remove(at: index)
            textFieldValue = components.joined(separator: "")

            if isValidExpression(textFieldValue) {
                calculateTotalValue()
            } else {
                if textFieldValue == "" {
                    totalValue = ""
                } else {
                    totalValue = "Invalid Equation"
                }
            }
        }
    }

    func clearTextField() {
        if totalValue != "Invalid Equation" {
            historyManager.saveCurrentEquationToHistory()
        }
        textFieldValue = ""
        previousText = ""
        deletedComponentsMap.removeAll()
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

        // Make sure on the main thread
        DispatchQueue.main.async {
            guard let windowScene = self.getWindowScene(),
                  let textField = self.findTextField(in: windowScene.windows.first!) else { return }

            // Check if text field has focus
            let hasFocus = textField.isFirstResponder

            if hasFocus {
                // If focused, use the current cursor position
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.performTextInsertionAtCursor(textField: textField, text: text)
                }
            } else {
                // If not focused, simply append to the end without changing focus
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    // Simply append the text to the current value
                    self.textFieldValue += text
                    textField.text = self.textFieldValue
                }
            }
        }
    }

    // New helper method to handle the actual insertion
    private func performTextInsertionAtCursor(textField: UITextField, text: String) {
        // If there's no valid selection range, append to the end without changing focus
        guard let selectedRange = textField.selectedTextRange else {
            // Just append the text
            self.textFieldValue += text
            textField.text = self.textFieldValue
            return
        }

        // Calculate new cursor position after insertion
        let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start) + text.count

        // Insert the given text at the current cursor position
        textField.replace(selectedRange, withText: text)

        // Restore cursor position after the inserted text
        if let newPosition = textField.position(from: textField.beginningOfDocument, offset: cursorPosition) {
            textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
        }

        // Update textFieldValue manually to ensure state is consistent
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
