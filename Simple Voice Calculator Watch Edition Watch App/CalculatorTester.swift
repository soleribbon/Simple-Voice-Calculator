//
//  CalculatorTester.swift
//  Simple Voice Calculator Watch Edition Watch App
//
//  Created by Ravi Heyne on 08/09/24.
//

import Foundation

struct CalculatorTester {
    let calculator: CalculatorLogic
    var processVoiceInput: (String) -> Void
    var getTotalValue: () -> String
    var clearEquation: () -> Void

    init(calculator: CalculatorLogic, processVoiceInput: @escaping (String) -> Void, getTotalValue: @escaping () -> String, clearEquation: @escaping () -> Void) {
        self.calculator = calculator
        self.processVoiceInput = processVoiceInput
        self.getTotalValue = getTotalValue
        self.clearEquation = clearEquation
    }

    func runInputTest() {
        let testCases: [(equation: String, expectedTotal: String)] = [
            ("3,000.435×-2+5", "-5995.87"), //Decimal test + negative multiplication
            ("10+20×3", "70"),  // Multiplication should occur before addition
            ("100÷2--30", "80"), // Division before subtraction + negative subtraction
            ("50-25×2+10", "10"), // Multiplication first, then addition and subtraction
            ("204+535-32÷4×5", "699"), // Division and multiplication, then addition and subtraction
            ("1+1", "2"), // Simple addition
            ("50×3-40÷8", "145"), // Multiplication first, then division, and subtraction
            ("-50+56÷1000000÷5+56", "6.00"), // Negative number before
            ("+50+56÷1000000÷5+56", "106.00"), // Positive number before
            ("50+-56÷1000000÷5+56", "106.00"), // Plus negative
            ("50+fifty÷5.00+56", "Invalid Equation"), // Invalid test
            ("100-25×3+10÷2", "30"), // Subtraction, multiplication, and division
            ("300+500×2-400÷4", "1200"), // All operators
            ("10×10+20×5-30÷3", "190"), // Three operations
            ("1000÷10+100×3-200", "200"), // Large numbers
            ("50×6÷3-4×5+10", "90"), // Mixed operations with complex precedence
            ("200+300×4-500÷2+100", "1250"), // Combining all four operators
            ("1000-50×2+100÷5", "920") // Division and multiplication precedence
        ]

        func runTest(at index: Int) {
            guard index < testCases.count else {
                print("All tests completed.")
                return
            }

            let testCase = testCases[index]

            // Process the input for the current equation
            self.processVoiceInput(testCase.equation)

            // Allow some time for the equation to be processed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // Compare the actual result with the expected result
                let actualTotal = self.getTotalValue()
                let expectedTotal = testCase.expectedTotal

                if actualTotal == expectedTotal {
                    print("✅ Passed: \(testCase.equation) = \(actualTotal)")
                } else {
                    print("❌ Failed: \(testCase.equation) expected \(expectedTotal), but got \(actualTotal)")
                }

                // Clear the equation after processing the result
                self.clearEquation()

                // Run the next test after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    runTest(at: index + 1)
                }
            }
        }

        // Start running tests
        runTest(at: 0)
    }
}
