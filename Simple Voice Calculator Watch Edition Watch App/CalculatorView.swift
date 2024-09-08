import SwiftUI
import WatchKit

struct CalculatorView: View {
    @State private var recognizedText: String = ""
    @State private var isListening: Bool = false
    @State private var equationComponents: [String] = []
    @State private var totalValue: String = "0"
    
    @State private var isSettingsModalPresented: Bool = false
    
    @State private var selectedComponentIndex: Int? = nil
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    
    @State private var scrollOffset: Double = 0 // Offset for crown rotation
    @State private var contentWidth: CGFloat = 0.0 // Calculated content width
    
    let calculator = CalculatorLogic()
    
    
    var body: some View {
        VStack {
            HStack {
                Button(action: showClearAlert) {
                    Text("Clear")
                        .accessibilityLabel("Clear")
                        .foregroundColor(.orange)
                    
                }
                .buttonStyle(.plain)
                .opacity(equationComponents.isEmpty ? 0 : 1)
                
                Spacer()
                //SETTINGS BUTTON
                Button(action: {
                    isSettingsModalPresented.toggle()
                    WKInterfaceDevice.current().play(.click)
                    
                }, label: {
                    Image(systemName: "gear.badge.questionmark")
                        .foregroundColor(.primary)
                    
                })
                .accessibilityLabel("Settings")
                .buttonStyle(.plain)
                .fullScreenCover(isPresented: $isSettingsModalPresented) {
                    SettingsView(isPresented: $isSettingsModalPresented)
                }
            }
            Spacer()
            //TOP HSTACK
            
            VStack {
                
                if equationComponents.isEmpty {
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
                                    ForEach(equationComponents.indices, id: \.self) { index in
                                        let component = equationComponents[index]
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
                                        .onChange(of: equationComponents) {
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
                        let length = totalValue.count
                        
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
                        
                        Text(totalValue)
                            .font(.system(size: fontSize)) // Apply the calculated font size
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(1) // Prevent text from wrapping
                            .minimumScaleFactor(0.75) // Slightly allow scaling down if needed
                            .frame(width: geometry.size.width, alignment: .trailing) // Align to the right
                    }
                    .frame(height: 30)
                }
                .opacity(equationComponents.isEmpty ? 0 : 1)
                
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
                        
                        if !equationComponents.isEmpty {
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
        .onChange(of: equationComponents) {
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

    func showClearAlert() {
        alertTitle = "Clear Equation?"
        alertMessage = ""//optional extra message

        WKInterfaceDevice.current().play(.click)

        WKExtension.shared().rootInterfaceController?.presentAlert(
            withTitle: alertTitle,
            message: alertMessage,
            preferredStyle: .actionSheet,
            actions: [
                WKAlertAction(title: "Clear", style: .destructive, handler: {
                    clearEquation()
                }),
                WKAlertAction(title: "Cancel", style: .cancel, handler: {})
            ]
        )
    }

    
    func deleteComponent(at index: Int) {
        equationComponents.remove(at: index)
        totalValue = calculator.calculateTotal(equationComponents: equationComponents)
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
        recognizedText = input
        let components = calculator.getEquationComponents(input)
        equationComponents.append(contentsOf: components)
        totalValue = calculator.calculateTotal(equationComponents: equationComponents)
    }
    
    func clearEquation() {
        WKInterfaceDevice.current().play(.start)
        
        saveEquation(equationComponents.joined(separator: ""))
        
        equationComponents = []
        totalValue = "0"
        scrollOffset = 0
    }
    
    func saveEquation(_ equation: String) {
        // Retrieve stored equations from UserDefaults
        var recentEquations = UserDefaults.standard.stringArray(forKey: "recentEquations") ?? []
        
        // Append the new equation
        recentEquations.append(equation)
        
        // Ensure we only store the last 3 equations
        if recentEquations.count > 3 {
            recentEquations.removeFirst()
        }
        
        // Save the updated array back to UserDefaults
        UserDefaults.standard.set(recentEquations, forKey: "recentEquations")
    }
    

    
    
    
}
#Preview {
    CalculatorView()
}
