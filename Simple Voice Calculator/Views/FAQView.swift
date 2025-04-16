//
//  FAQView.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 14/04/25.
//

import SwiftUI

struct FAQView: View {
    @Environment(\.openURL) private var openURL
    
    // Track which question is expanded
    @State private var expandedIndex: Int? = nil
    

    private func localizedFAQTitle(_ english: String) -> LocalizedStringKey {
        // 1 exact key?
        if NSLocalizedString(english, comment: "") != english {
            return LocalizedStringKey(english)          // found
        }
        // 2 try the bolded form
        let boldKey = "**\(english)**"
        if NSLocalizedString(boldKey, comment: "") != boldKey {
            return LocalizedStringKey(boldKey)          // found
        }
        // 3 fallback – show the English string
        return LocalizedStringKey(english)
    }

    private let faqItems: [(question: String, answerView: AnyView)] = [
        (
            "What math operators are supported?",
            AnyView(
                Text("""
                     Currently supported operators:
                     + - × ÷ %
                     """)
            )
        ),
        (
            "What does 'Invalid Equation' mean?",
            AnyView(
                Text("Invalid Equation is presented when the textfield contains characters that are not valid in a mathematical equation or not currently supported.")
            )
        ),
        (
            "What does the 'Sym' button do?",
            AnyView(
                Text("The Sym button can be used to insert a desired math symbol where your cursor is placed in the textfield.")
            )
        ),
        (
            "How do I edit my voice input?",
            AnyView(
                Text("You can edit any component of your equation in the 'Equation Components' section. Just tap you desired components and it will be selected in your textfield. Make sure you do not have voice input enabled (button should say 'Start Talking').")
            )
        ),
        (
            "What is PRO Mode?",
            AnyView(
                VStack(alignment: .leading, spacing: 6) {
                    Text("PRO Mode includes the following features:")
                    
                    Text("• **History** – Quickly access and reuse past equations. You can apply past totals to your current equation with any operator.")
                    Text("• **Favorites** – Save your most-used equations for easy retrieval.")
                    Text("• **iCloud Sync** – Keep your equation history and favorites consistent across all devices.")
                    Text("• **Siri Support** (coming soon) – Perform accurate calculations with Siri.")
                }
            )
        ),
        (
            "How do I use parentheses in equations?",
            AnyView(
                Text("You can easily input equations with parentheses simply by saying 'open parenthesis' or 'open bracket' and 'close parenthesis' or 'close bracket' while recording. Always make sure to include a closing parenthesis, or you may end up with an invalid equation.")
                
            )
        ),
        
        (
            "How do I cancel my PRO subscription?",
            AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    // Original text
                    Text("""
                         You can cancel your PRO subscription by visiting your App Store subscription settings.
                         """)
                    .fixedSize(horizontal: false, vertical: true)
                    
                    // Tappable link text
                    Text("Find out more here")
                        .foregroundColor(.blue)
                        .underline()
                        .onTapGesture {
                            // Forward user to the App Store (Apple subscription info page)
                            let url = URL.init(string: "https://support.apple.com/en-us/HT202039")
                            guard let appStoreURL = url, UIApplication.shared.canOpenURL(appStoreURL) else { return }
                            UIApplication.shared.open(appStoreURL)
                        }
                }
            )
        ),
        (
            "I have another question...",
            AnyView(
                VStack(alignment: .leading, spacing: 8) {
                    Text("We value all your feedback. If you have a question not covered here, please feel free to reach out anytime for help or additional information.")
                    
                    // Tappable mailto link
                    Text("Email Developer")
                        .foregroundColor(.blue)
                        .underline()
                        .onTapGesture {
                            if let emailURL = URL(string: "mailto:raviheyne@gmail.com") {
                                UIApplication.shared.open(emailURL)
                            }
                        }
                }
            )
        )
        
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                VStack (alignment: .center){
                    
                    Image(systemName: "questionmark.square.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .font(.title2)
                    
                    
                    Text("Frequent Questions")
                        .font(.title2.weight(.bold))
                        .padding(.vertical, 6)
                    
                }
                List {
                    ForEach(faqItems.indices, id: \.self) { index in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedIndex == index },
                                set: { expandedIndex = $0 ? index : nil }

                            )
                        ) {
                            // The “answer” (wrapped in AnyView above)
                            faqItems[index].answerView
                                .font(.body)
                                .padding(.vertical, 4)
                        } label: {
                            // The “question”
                            Text(localizedFAQTitle(faqItems[index].question))
                                .font(.headline)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

#Preview {
    FAQView()
}
