import SwiftUI
import WatchKit
import AVFoundation

struct CalculatorView: View {
    @ObservedObject var calculatorModel: CalculatorModel
    @State private var isListening: Bool = false
    @State private var selectedComponentIndex: Int? = nil
    @State private var scrollOffset: Double = 0
    @State private var contentWidth: CGFloat = 0.0

    @AppStorage("shouldSpeakTotal") var shouldSpeakTotal: Bool = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    let calculator = CalculatorLogic()
    @State private var currentLanguage = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")

    var body: some View {
        VStack {
            Spacer()
            ZStack {
                if calculatorModel.equationComponents.isEmpty {
                    emptyEquationView
                } else {
                    VStack {
                        equationComponentsView
                        totalView
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: calculatorModel.equationComponents.isEmpty)
            .transition(.opacity)
            recordButton
        }
        .padding(.horizontal)
        .onChange(of: calculatorModel.equationComponents) {
            scrollOffset = 0
        }
    }

    var emptyEquationView: some View {
        VStack {
            Image("recordEquation")
                .resizable()
                .scaledToFit()
                .frame(height: 90)
        }
    }

    var equationComponentsView: some View {
        EquationScrollView(
            calculatorModel: calculatorModel,
            calculator: calculator,
            contentWidth: $contentWidth,
            scrollOffset: $scrollOffset,
            selectedComponentIndex: $selectedComponentIndex,
            showDeletionAlert: showDeletionAlert(for:)
        )
        .frame(height: 50)
    }

    var totalView: some View {
        HStack(alignment: .center) {
            Text("TOTAL")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
            Text(calculatorModel.totalValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .opacity(calculatorModel.equationComponents.isEmpty ? 0 : 1)
        .padding(.vertical)
    }

    var recordButton: some View {
        Button(action: {
            WKInterfaceDevice.current().play(.click)
            withAnimation {
                isListening.toggle()
            }
            if isListening {
                launchVoiceInput()
            }
        }) {
            ZStack {
                Circle()
                    .fill(isListening ? Color.red : Color.blue)
                    .frame(width: 60, height: 60)
                Image(systemName: isListening ? "waveform" : "mic.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 26))
                if !calculatorModel.equationComponents.isEmpty {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                        .offset(x: 10, y: -10)
                }
            }
        }
        //        .padding(.bottom, calculatorModel.equationComponents.isEmpty ? 40 : 0)
        .padding(.bottom, 20)
        .disabled(isListening)
    }

    func showDeletionAlert(for component: String) {
        let alertTitle = "Delete \(component)?"
        let alertMessage = ""
        WKInterfaceDevice.current().play(.click)
        WKExtension.shared().rootInterfaceController?.presentAlert(
            withTitle: alertTitle,
            message: alertMessage,
            preferredStyle: .actionSheet,
            actions: [
                WKAlertAction(title: "Delete", style: .destructive, handler: {
                    if let index = selectedComponentIndex {
                        deleteComponent(at: index)
                    }
                }),
                WKAlertAction(title: "Cancel", style: .cancel, handler: {})
            ]
        )
    }

    func deleteComponent(at index: Int) {
        calculatorModel.equationComponents.remove(at: index)
        calculatorModel.totalValue = calculator.calculateTotal(equationComponents: calculatorModel.equationComponents)
        WKInterfaceDevice.current().play(.failure)
    }

    func launchVoiceInput() {
        let recentEquations = UserDefaults.standard.stringArray(forKey: "recentEquations") ?? ["1+2", "30.5÷6", "17×6-5"]
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            WKExtension.shared().rootInterfaceController?.presentTextInputController(
                withSuggestions: recentEquations,
                allowedInputMode: .plain
            ) { results in
                defer {
                    withAnimation {
                        isListening = false
                    }
                }
                guard let result = results?.first as? String else { return }
                processVoiceInput(result)
            }
        }
    }

    func processVoiceInput(_ input: String) {
        DispatchQueue.main.async {
            let components = calculator.getEquationComponents(input)
            calculatorModel.equationComponents.append(contentsOf: components)
            calculatorModel.totalValue = calculator.calculateTotal(equationComponents: calculatorModel.equationComponents)
            if shouldSpeakTotal && !calculatorModel.totalValue.isEmpty && calculatorModel.totalValue != "Invalid Equation" {
                speakTotal(calculatorModel.totalValue)
            }
        }
    }

    func speakTotal(_ total: String) {
        let totalString = String(format: NSLocalizedString("Total equals %@", comment: ""), total)
        let utterance = AVSpeechUtterance(string: totalString)
        if let voice = AVSpeechSynthesisVoice(language: currentLanguage) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        DispatchQueue.main.async {
            speechSynthesizer.speak(utterance)
        }
    }
}

struct EquationScrollView: View {
    @ObservedObject var calculatorModel: CalculatorModel
    let calculator: CalculatorLogic
    @Binding var contentWidth: CGFloat
    @Binding var scrollOffset: Double
    @Binding var selectedComponentIndex: Int?
    let showDeletionAlert: (String) -> Void


    var body: some View {
        GeometryReader { geometry in
            let visibleWidth = geometry.size.width
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(calculatorModel.equationComponents.indices, id: \.self) { index in
                        let component = calculatorModel.equationComponents[index]
                        let symbolColor = calculator.getSymbolColor(component: component)
                        Text(component)
                            .font(.headline)
                            .foregroundColor(symbolColor.foreground)
                            .padding(8)
                            .background(symbolColor.background)
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedComponentIndex = index
                                showDeletionAlert(component)
                            }
                    }
                }
                .background(
                    GeometryReader { hstackGeometry in
                        Color.clear.onAppear {
                            contentWidth = hstackGeometry.size.width
                        }
                        .onChange(of: calculatorModel.equationComponents) {
                            let previousWidth = contentWidth
                            contentWidth = hstackGeometry.size.width
                            if contentWidth > previousWidth {
                                withAnimation {
                                    scrollOffset = Double(max(contentWidth - visibleWidth, 0))
                                }
                            }
                        }
                    }
                )
                .focusable(true)
                .digitalCrownRotation(
                    $scrollOffset,
                    from: 0,
                    through: Double(max(contentWidth - visibleWidth, 0)),
                    by: 5,
                    sensitivity: .high,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .offset(x: -scrollOffset)
                .scrollIndicators(.hidden)
            }
        }
    }
}


#Preview {
    CalculatorView(calculatorModel: CalculatorModel())
}
