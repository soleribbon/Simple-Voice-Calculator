//
//  HistoryView.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 26/03/25.
//

import SwiftUI
import Mixpanel

// MARK: - History Mode Enum
enum HistoryMode: Int {
    case replace = 0
    case add = 1
    case subtract = 2
    case multiply = 3
    case divide = 4
    
    // SF Symbol for the operation
    var sfSymbol: String {
        switch self {
        case .replace: return "rectangle.2.swap"
        case .add: return "plus"
        case .subtract: return "minus"
        case .multiply: return "multiply"
        case .divide: return "divide"
        }
    }
    
    // Operation symbol for calculations
    var operationSymbol: String {
        switch self {
        case .replace: return ""
        case .add: return "+"
        case .subtract: return "-"
        case .multiply: return "×"
        case .divide: return "÷"
        }
    }
    
    // Color for the mode
    var color: Color {
        switch self {
        case .replace: return Color(.systemPink)
        case .add: return .green
        case .subtract: return .red
        case .multiply: return .blue
        case .divide: return Color(red: 1.0, green: 0.7, blue: 0.0)
        }
    }
}


// MARK: - History Manager Extensions
extension HistoryManager {
    func clearAllHistory() {
        historyItems = []
        currentEquation = ""
        currentResult = ""
        saveHistory()
    }
    
    // Get items older than yesterday
    var olderItems: [HistoryItem] {
        let calendar = Calendar.current
        return historyItems.filter { item in
            !calendar.isDateInToday(item.date) && !calendar.isDateInYesterday(item.date)
        }
    }
}

// MARK: - Updated Main History View
struct HistoryView: View {
    // MARK: Properties
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var historyManager: HistoryManager
    @State private var showingClearConfirmation = false
    @State private var clearButtonScale: CGFloat = 1.0
    
    // Haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    let impactClear = UIImpactFeedbackGenerator(style: .heavy)
    
    // Handle when an equation is selected from history
    var onEquationSelected: ((String) -> Void)?
    var onEquationOperation: ((String, String) -> Void)?
    
    // MARK: Computed Properties
    // Group history items by date section
    private var historyByDate: [String: [HistoryItem]] {
        let calendar = Calendar.current
        var groupedItems: [String: [HistoryItem]] = [:]
        
        for item in historyManager.historyItems {
            let sectionTitle: String
            
            if calendar.isDateInToday(item.date) {
                sectionTitle = "TODAY"
            } else if calendar.isDateInYesterday(item.date) {
                sectionTitle = "YESTERDAY"
            } else {
                // Format date for older items
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM d, yyyy"
                sectionTitle = formatter.string(from: item.date)
            }
            
            if groupedItems[sectionTitle] == nil {
                groupedItems[sectionTitle] = []
            }
            
            groupedItems[sectionTitle]?.append(item)
        }
        
        return groupedItems
    }
    
    // Sort section keys by date
    private var sortedSectionKeys: [String] {
        let sections = Array(historyByDate.keys)
        return sections.sorted { section1, section2 in
            if section1 == "TODAY" { return true }
            if section2 == "TODAY" { return false }
            if section1 == "YESTERDAY" { return true }
            if section2 == "YESTERDAY" { return false }
            return section1 > section2 // Compare dates newest to oldest
        }
    }
    
    // MARK: Helper Methods
    private func deleteItemsFromSection(at offsets: IndexSet, in section: String) {
        // Convert IndexSet to actual items to delete
        if let items = historyByDate[section] {
            let itemsToDelete = offsets.map { items[$0] }
            
            // Remove items from history manager
            historyManager.deleteItems(itemsToDelete)
        }
    }
    
    // Handle history item actions
    private func handleHistoryAction(item: HistoryItem, mode: HistoryMode) {
        switch mode {
        case .replace:
            onEquationSelected?(item.equation)
        case .subtract:
            // Check if current equation is empty
            if historyManager.currentEquation.isEmpty {
                // If empty and the result is already negative, don't add another minus
                if item.result.hasPrefix("-") {
                    onEquationSelected?(item.result)
                } else {
                    // For positive numbers, add the negative sign
                    // Force string conversion to ensure proper concatenation
                    let negativeResult = "-" + item.result
                    onEquationSelected?(negativeResult)
                }
            } else {
                // Normal operation (append with operator)
                onEquationOperation?(item.result, mode.operationSymbol)
            }
        case .add, .multiply, .divide:
            onEquationOperation?(item.result, mode.operationSymbol)
        }
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 4) {
            Text("No calculation history yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Your calculations will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: History List View
    private var historyListView: some View {
        List {
            ForEach(sortedSectionKeys, id: \.self) { section in
                if let items = historyByDate[section], !items.isEmpty {
                    Section(header: Text(section)) {
                        ForEach(items) { item in
                            HistoryRow(
                                equation: item.equation,
                                result: item.result,
                                onAction: { mode in
                                    handleHistoryAction(item: item, mode: mode)
                                }
                            )
                        }
                        .onDelete { indexSet in
                            // Swipe-to-delete functionality
                            deleteItemsFromSection(at: indexSet, in: section)
                        }
                    }
                }
            }
            Color.clear
                .frame(height: 10)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: Bottom Controls View
    private var bottomControlsView: some View {
        VStack {
            Spacer()
            
            HStack {
                
                // Clear button
                Button(action: {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        clearButtonScale = 0.95
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            clearButtonScale = 1.0
                        }
                    }
                    showingClearConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear History")
                    }
                    .ActionButtons(isRecording: false, bgColor: Color.orange)
                }
                .scaleEffect(clearButtonScale)
                .background(
                    //Blur effect for button (restored from original)
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.primary.opacity(0.05))
                        .background(Color(UIColor.systemBackground))
                        .blur(radius: 30)
                        .padding(-15)
                    
                )
                
                Spacer()
            }
            .padding(.bottom)
            
            .padding(.horizontal)
            
        }
    }
    
    // MARK: Body
    var body: some View {
        NavigationView {
            ZStack {
                if historyManager.historyItems.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                    bottomControlsView
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                            .font(.body)
                    }
                }
            }
            .alert(isPresented: $showingClearConfirmation) {
                Alert(
                    title: Text("Clear History"),
                    message: Text("Are you sure you want to clear all calculation history?"),
                    primaryButton: .destructive(Text("Clear")) {
                        withAnimation {
                            impactClear.impactOccurred()
                            historyManager.clearAllHistory()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
        .environmentObject(HistoryManager())
}
