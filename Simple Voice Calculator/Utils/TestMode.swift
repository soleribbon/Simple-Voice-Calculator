//
//  TestMode.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 31/03/25.
//

import Foundation

struct TestCase: Identifiable {
    let id = UUID()
    let input: String
    let expectedOutput: String
    var actualOutput: String = ""
    var passed: Bool = false
}

// Manages test mode functionality
class TestMode: ObservableObject {
    @Published var isTestModeActive = false
    @Published var testCases: [TestCase] = []
    @Published var currentTestIndex: Int = 0
    @Published var testingInProgress = false
    @Published var testsFinished = false
    @Published var passedCount = 0
    @Published var failedCount = 0
    
    // Initialize with standard test cases
    init() {
        setupTestCases()
    }
    
    // Setup all test cases
    func setupTestCases() {
        testCases = [
            TestCase(input: "3,000.435×-2+5", expectedOutput: "-5995.870"),
            TestCase(input: "10+20×3", expectedOutput: "70"),
            TestCase(input: "100÷2--30", expectedOutput: "80"),
            TestCase(input: "50-25×2+10", expectedOutput: "10"),
            TestCase(input: "204+535-32÷4×5", expectedOutput: "699"),
            TestCase(input: "1+1", expectedOutput: "2"),
            TestCase(input: "50×3-40÷8", expectedOutput: "145"),
            TestCase(input: "50×3-40 divided by 8", expectedOutput: "145"),
            TestCase(input: "50×3-40 dividedby 8", expectedOutput: "145"),
            TestCase(input: "-50+56÷1000000÷5+56", expectedOutput: "6.000"),
            TestCase(input: "+50+56÷1000000÷5+56", expectedOutput: "106.000"),
            TestCase(input: "50+-56÷1000000÷5+56", expectedOutput: "106.000"),
            TestCase(input: "50+fifty÷5.00+56", expectedOutput: "Invalid Equation"),
            TestCase(input: "100-25×3+10÷2", expectedOutput: "30"),
            TestCase(input: "300+500×2-400÷4", expectedOutput: "1200"),
            TestCase(input: "10×10+20×5-30÷3", expectedOutput: "190"),
            TestCase(input: "1000÷10+100×3-200", expectedOutput: "200"),
            TestCase(input: "50×6÷3-4×5+10", expectedOutput: "90"),
            TestCase(input: "200+300×4-500÷2+100", expectedOutput: "1250"),
            TestCase(input: "1000-50×2+100÷5", expectedOutput: "920")
        ]
    }
    
    // Reset all test results
    func resetTests() {
        for i in 0..<testCases.count {
            testCases[i].actualOutput = ""
            testCases[i].passed = false
        }
        currentTestIndex = 0
        testingInProgress = false
        testsFinished = false
        passedCount = 0
        failedCount = 0
    }
    
    // Record a test result
    func recordTestResult(input: String, output: String) {
        if let index = testCases.firstIndex(where: { $0.input == input }) {
            testCases[index].actualOutput = output
            testCases[index].passed = output == testCases[index].expectedOutput
            
            if testCases[index].passed {
                passedCount += 1
            } else {
                failedCount += 1
            }
        }
    }
    
    // Check if current test case
    var hasCurrentTest: Bool {
        currentTestIndex < testCases.count
    }
    
    // Get the current test case
    var currentTest: TestCase? {
        if hasCurrentTest {
            return testCases[currentTestIndex]
        }
        return nil
    }
    
    // Move to the next test
    func moveToNextTest() {
        if currentTestIndex < testCases.count - 1 {
            currentTestIndex += 1
        } else {
            testsFinished = true
            testingInProgress = false
        }
    }
    
    // Start the test process
    func startTesting() {
        resetTests()
        testingInProgress = true
    }
}
