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
    
    // Get the next mode in the cycle
    var next: HistoryMode {
        switch self {
        case .replace: return .add
        case .add: return .subtract
        case .subtract: return .multiply
        case .multiply: return .divide
        case .divide: return .replace
        }
    }
    
    // SF Symbol for the current mode
    var sfSymbol: String {
        switch self {
        case .replace: return "arrow.right"
        case .add: return "plus"
        case .subtract: return "minus"
        case .multiply: return "multiply"
        case .divide: return "divide"
        }
    }
    
    // Button title text
    var buttonTitle: String {
        switch self {
        case .replace: return "Tap to REPLACE"
        case .add: return "Tap to ADD"
        case .subtract: return "Tap to SUBTRACT"
        case .multiply: return "Tap to MULTIPLY"
        case .divide: return "Tap to DIVIDE"
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
    
    // Color for the mode button
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

// MARK: - History Row Component
struct HistoryRowWithMode: View {
    var equation: String
    var result: String
    var mode: HistoryMode
    var onTap: () -> Void
    
    // State for animation
    @State private var itemScale: CGFloat = 1.0
    
    let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        HStack {
            Text(equation)
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .font(.body)
            
            Spacer()
            
            HStack {
                Text("=")
                    .foregroundColor(.primary)
                    .font(.body)
                    .opacity(0.3)
                Text(result)
                    .foregroundColor(.primary)
                    .font(.body)
                    .bold()
            }
            .padding(.vertical)
            .padding(.leading)
            
            Button(action: {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    itemScale = 0.95
                }
                
                switch mode {
                case .replace:
                    heavyImpact.impactOccurred()
                case .add, .subtract, .multiply, .divide:
                    mediumImpact.impactOccurred()
                }
                
                // Reset scale after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        itemScale = 1.0
                    }
                    
                    // Call the original onTap action after animation starts
                    onTap()
                }
            }) {
                Image(systemName: mode.sfSymbol)
                    .foregroundColor(mode.color)
                    .font(.headline)
            }
        }
        .scaleEffect(itemScale)
        .contentShape(Rectangle())
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.tertiarySystemBackground))
                .padding(
                    EdgeInsets(
                        top: 4,
                        leading: 0,
                        bottom: 4,
                        trailing: 0
                    )
                )
        )
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

// MARK: - Main History View
struct HistoryView: View {
    // MARK: Properties
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var historyManager: HistoryManager
    @State private var showingClearConfirmation = false
    @State private var clearButtonScale: CGFloat = 1.0
    @State private var modeButtonScale: CGFloat = 1.0
    
    // Haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // State to track the active mode
    @AppStorage("historyViewMode") private var storedMode: Int = 0
    @State private var currentMode: HistoryMode = .replace
    
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
                            HistoryRowWithMode(
                                equation: item.equation,
                                result: item.result,
                                mode: currentMode,
                                onTap: {
                                    switch currentMode {
                                    case .replace:
                                        onEquationSelected?(item.equation)
                                    case .add, .subtract, .multiply, .divide:
                                        onEquationOperation?(item.result, currentMode.operationSymbol)
                                    }
                                    presentationMode.wrappedValue.dismiss()
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
                // Mode cycling button with consistent width
                Button(action: {
                    impactFeedback.impactOccurred()
                    
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        modeButtonScale = 0.95
                        currentMode = currentMode.next // Cycle to next mode
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            modeButtonScale = 1.0
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: currentMode.sfSymbol)
                        Text(currentMode.buttonTitle)
                    }
                    .frame(minWidth: 180) // Consistent width
                    .ActionButtons(isRecording: false, bgColor: currentMode.color)
                    .shadow(color: currentMode.color.opacity(0.05), radius: 10, x: 0, y: 5)
                }
                .scaleEffect(modeButtonScale)
                
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
                        Text("Clear")
                    }
                    .ActionButtons(isRecording: false, bgColor: Color.orange)
                }
                .scaleEffect(clearButtonScale)
            }
            .background(
                // Blur effect for both buttons
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primary.opacity(0.05))
                    .background(Color(UIColor.systemBackground))
                    .blur(radius: 20)
                    .padding(-15)
            )
            .padding(.horizontal)
            .padding(.bottom, 16)
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
                            historyManager.clearAllHistory()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .onAppear {
            // Convert stored integer to HistoryMode
            currentMode = HistoryMode(rawValue: storedMode) ?? .replace
        }
        .onChange(of: currentMode) { newMode in
            // Store the raw value of the mode when it changes
            storedMode = newMode.rawValue
        }
    }
}

// MARK: - Preview
#Preview {
    HistoryView()
        .environmentObject(HistoryManager())
}
