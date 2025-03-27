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
                    isHistoryModalPresented = true
                }) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .foregroundColor(.primary)
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
                onEquationOperation: { historyEquation, operation in
                    if !textFieldValue.isEmpty && operation != "" {
                        textFieldValue = "(\(textFieldValue))\(operation)(\(historyEquation))"
                        calculateTotalValue()
                    } else {
                        textFieldValue = historyEquation
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

    // Rest of your CalculatorView methods
    // [...]
}
extension CalculatorView {
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
            textFieldValue = getEquationComponents().joined(separator: "")
            //speak out total
            if shouldSpeakTotal && !totalValue.isEmpty && totalValue != "Invalid Equation" {
                speakTotal(totalValue)
            }
        }
        completion()
    }

    func clearTextField() {
        historyManager.saveCurrentEquationToHistory()
        textFieldValue = ""
        previousText = ""
    }

    func updateTextFieldValue() {
        guard let windowScene = getWindowScene(),
              let textField = findTextField(in: windowScene.windows.first!) else { return }
        textFieldValue = textField.text ?? ""
    }

    private func insertText(_ text: String) {
        //Make sure we're on the main thread
        DispatchQueue.main.async {
            guard let windowScene = getWindowScene(),
                  let textField = findTextField(in: windowScene.windows.first!) else { return }

            // Check if text field has focus first
            if !textField.isFirstResponder {
                textField.becomeFirstResponder()

                // Give it a moment to establish the input session
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.performTextInsertion(textField: textField, text: text)
                }
            } else {
                self.performTextInsertion(textField: textField, text: text)
            }
        }
    }

    // New helper method to handle the actual insertion
    private func performTextInsertion(textField: UITextField, text: String) {
        // Null safety check
        guard let selectedRange = textField.selectedTextRange else {
            // Fallback when no selection range exists
            let newText = (textField.text ?? "") + text
            textField.text = newText
            textFieldValue = newText
            return
        }

        let startPosition = selectedRange.start
        if startPosition == textField.beginningOfDocument {
            textField.selectedTextRange = textField.textRange(
                from: textField.endOfDocument,
                to: textField.endOfDocument
            )
        }

        // We need to get the selection range again to be safe
        if let currentRange = textField.selectedTextRange {
            // Removed: Cursor position calculation that could fail
            // Simplified: Just insert the text without trying to restore position
            textField.replace(currentRange, withText: text)

            textFieldValue = textField.text ?? ""
        } else {
            // Another fallback
            let newText = (textField.text ?? "") + text
            textField.text = newText
            textFieldValue = newText
        }
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
