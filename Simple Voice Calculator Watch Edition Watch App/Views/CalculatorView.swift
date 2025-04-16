import SwiftUI
import WatchKit
import AVFoundation

struct CalculatorView: View {
    @ObservedObject var calculatorModel: CalculatorModel
    let calculator: CalculatorLogic
    let calculatorTester: CalculatorTester
    init(calculatorModel: CalculatorModel) {
        self.calculatorModel = calculatorModel
        self.calculator = CalculatorLogic()
        self.calculatorTester = CalculatorTester(calculatorModel: calculatorModel)
    }
    
    @State private var isListening: Bool = false
    @State private var selectedComponentIndex: Int? = nil
    @State private var scrollOffset: Double = 0
    @State private var contentWidth: CGFloat = 0.0
    
    @AppStorage("shouldSpeakTotal") var shouldSpeakTotal: Bool = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    
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
                            .padding([.vertical])
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: calculatorModel.equationComponents.isEmpty)
            .transition(.opacity)
            
            recordButton
                .padding([.bottom], 20)
        }
        
        .padding(.horizontal)
        .onChange(of: calculatorModel.equationComponents) {
            scrollOffset = 0
        }
    }
    
    var emptyEquationView: some View {
        VStack {
            Text("Record Equation")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.bottom, 40)
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
        
        .padding(.bottom)
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
                if !calculatorModel.equationComponents.isEmpty {
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [isListening ? Color.red.opacity(0.8) : Color.blue.opacity(0.8), isListening ? Color.red : Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(isListening ? Color.red.opacity(0.8) : Color.blue.opacity(0.8), lineWidth: 6) // Stroke color changes when recording
                        )
                        .shadow(radius: 6)
                    
                    Image(systemName: isListening ? "waveform" : "mic.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 28))
                        .shadow(radius: 4)
                    
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                        .offset(x: 12, y: -12)
                        .shadow(radius: 2)
                } else {
                    // Nothing inputted yet
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [isListening ? Color.red.opacity(0.8) : Color.blue.opacity(0.8), isListening ? Color.red : Color.blue]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(isListening ? Color.red.opacity(0.8) : Color.blue.opacity(0.8), lineWidth: 6) // Stroke color changes when recording
                        )
                        .shadow(radius: 8)
                    
                    Image(systemName: isListening ? "waveform" : "mic.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 34))
                        .shadow(radius: 5)
                }
            }
        }
        .buttonStyle(BorderedButtonStyle(tint: .clear))
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
