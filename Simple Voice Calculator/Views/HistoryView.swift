//
//  HistoryView.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 26/03/25.
//

import SwiftUI
import Mixpanel

struct HistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var historyManager: HistoryManager
    @State private var showingClearConfirmation = false
    @State private var clearButtonScale: CGFloat = 1.0
    
    // Handle when an equation is selected from history
    var onEquationSelected: ((String) -> Void)?
    
    var onEquationOperation: ((String, String) -> Void)?
    
    
    
    
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
    
    // Sort section keys by date (TODAY, YESTERDAY, then older dates)
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
    
    var body: some View {
        NavigationView {
            ZStack {
                if historyManager.historyItems.isEmpty {
                    // Empty state view
                    VStack(spacing: 4) {
                        Text("No calculation history yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Your calculations will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(sortedSectionKeys, id: \.self) { section in
                            if let items = historyByDate[section], !items.isEmpty {
                                Section(header: Text(section)) {
                                    ForEach(items) { item in
                                        HistoryRow(equation: item.equation, onTap: {
                                            onEquationSelected?(item.equation)
                                            presentationMode.wrappedValue.dismiss()
                                        })
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    
                    // Clear history button at the bottom
                    VStack {
                        Spacer()
                        Button(action: {
                            // Add tap animation
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                clearButtonScale = 0.95
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                    clearButtonScale = 1.0
                                }
                            }
                            
                            // Show confirmation alert
                            showingClearConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear")
                            }
                            .ActionButtons(isRecording: false, bgColor: Color.orange)
                        }
                        .scaleEffect(clearButtonScale)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                        
                    }
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
    }
}

// We need to extend HistoryManager to add clearAllHistory function
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

struct HistoryRow: View {
    var equation: String
    var onTap: () -> Void
    
    var body: some View {
        HStack {
            Text(equation)
                .foregroundColor(.primary)
                .padding(.vertical, 8)
            
            Spacer()
            
            Button(action: onTap) {
                Image(systemName: "plus")
                    .foregroundColor(.blue)
                    .font(.headline)
            }
        }
        .contentShape(Rectangle())
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
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

#Preview {
    HistoryView()
        .environmentObject(HistoryManager())
}
