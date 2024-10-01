import SwiftUI
import WatchKit
import AVFoundation

struct CalculatorView: View {
    @State private var recognizedText: String = ""
    @State private var isListening: Bool = false
    
    @ObservedObject var calculatorModel: CalculatorModel
    
    
    @AppStorage("shouldSpeakTotal") var shouldSpeakTotal: Bool = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    @State private var isSettingsModalPresented: Bool = false
    @State private var selectedComponentIndex: Int? = nil
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    
    @State private var scrollOffset: Double = 0 // Offset for crown rotation
    @State private var contentWidth: CGFloat = 0.0 // Calculated content width
    
    let supportedLanguages = ["en-US", "de-DE", "es-ES", "es-MX", "it-IT", "ko-KR", "hi-IN"]
    @State var currentLanguage = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    
    let calculator = CalculatorLogic()
    
    
    var body: some View {
        VStack {
            
            Spacer()
            //TOP HSTACK
            
            VStack {
                
                if calculatorModel.equationComponents.isEmpty {
                    VStack {
                        Image("recordEquation")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 120)
                        
                    }.frame(height: 50)
                    Spacer()
                } else{
                    
                    VStack {
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
                                                showDeletionAlert(for: component)
                                            }
                                    }
                                }
                                // Calculate total width of the content inside HStack
                                .background(
                                    GeometryReader { hstackGeometry in
                                        Color.clear.onAppear {
                                            contentWidth = hstackGeometry.size.width
                                        }
                                        .onChange(of: calculatorModel.equationComponents) {
                                            let previousWidth = contentWidth
                                            contentWidth = hstackGeometry.size.width
                                            
                                            // Only animate to the end if new components are added and the width increased
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
                        .frame(height: 50)
                        
                        Spacer()
                    }
                    
                }//else
                Spacer()
                
                HStack (alignment: .center) {
                    Text("TOTAL")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        let length = calculatorModel.totalValue.count
                        
                        // Set the maximum and minimum font size
                        let maxFontSize: CGFloat = 24
                        let minFontSize: CGFloat = 16
                        
                        // Adjust the font size based on the length of the total value
                        let fontSize: CGFloat = {
                            if length <= 6 {
                                return maxFontSize // If the value is short, use the maximum font size
                            } else {
                                let calculatedFontSize = width / CGFloat(length)
                                return min(maxFontSize, max(minFontSize, calculatedFontSize)) // Ensure font size stays within the range
                            }
                        }()
                        
                        Text(calculatorModel.totalValue)
                            .font(.system(size: fontSize)) // Apply the calculated font size
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(1) // Prevent text from wrapping
                            .minimumScaleFactor(0.75) // Slightly allow scaling down if needed
                            .frame(width: geometry.size.width, alignment: .trailing) // Align to the right
                    }
                    .frame(height: 30)
                }
                .opacity(calculatorModel.equationComponents.isEmpty ? 0 : 1)
                .padding()
                
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    
                    
                    //FOR TESTING
                    //                    let tester = CalculatorTester(
                    //                        calculator: calculator,
                    //                        processVoiceInput: { self.processVoiceInput($0) },
                    //                        getTotalValue: { self.totalValue },
                    //                        clearEquation: { self.clearEquation() }
                    //                    )
                    //                    tester.runInputTest()
                    
                    
                    
                    withAnimation {
                        isListening.toggle()
                    }
                    if isListening {
                        launchVoiceInput()  // Start voice input
                    }
                    
                }) {
                    ZStack {
                        Image(systemName: isListening ? "waveform" : "mic.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(isListening ? .red : .blue)
                            .transition(.scale)
                        
                        if !calculatorModel.equationComponents.isEmpty {
                            Image(systemName: "plus")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .bold()
                                .frame(width: 10, height: 10)
                                .foregroundColor(.blue)
                                .offset(x: 10, y: -14)
                        }
                    }
                }
                .disabled(isListening)
            }
            
        }
        .onChange(of: calculatorModel.equationComponents) {
            //            totalValue = calculator.calculateTotal(equationComponents: equationComponents)
            scrollOffset = 0
        }
        
    }
    
    func showDeletionAlert(for component: String) {
        alertTitle = "Delete \(component)?"
        alertMessage = ""//optional extra message
        
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
        // Fetch recent equations from UserDefaults
        let recentEquations = UserDefaults.standard.stringArray(forKey: "recentEquations") ?? ["1+2", "30.5÷6", "17×6-5"]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
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
            recognizedText = input
            let components = calculator.getEquationComponents(input)
            calculatorModel.equationComponents.append(contentsOf: components)
            calculatorModel.totalValue = calculator.calculateTotal(equationComponents: calculatorModel.equationComponents)
            if shouldSpeakTotal && !calculatorModel.totalValue.isEmpty && calculatorModel.totalValue != "Invalid Equation" {
                speakTotal(calculatorModel.totalValue)
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
            
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        DispatchQueue.main.async {
            speechSynthesizer.speak(utterance)
        }
    }
    
   
    
    
    
    
    
    
    
}
#Preview {
    CalculatorView(calculatorModel: CalculatorModel())
}
