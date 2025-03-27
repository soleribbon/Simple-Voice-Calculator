//
//  TotalDisplayView.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 27/03/25.
//

import SwiftUI

struct TotalDisplayView: View {
    let totalValue: String
    var onTap: () -> Void
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text("TOTAL:")
                    .font(.body)
                    .foregroundColor(.black)
                    .opacity(0.5)
                Spacer()
                Text("=")
                    .foregroundColor(.black)
                    .accessibilityLabel("=")
                    .opacity(0.3)
                Text(totalValue)
                    .font(.system(.headline, design: .monospaced))
                    .bold()
                    .foregroundColor(.black)
            }
            .padding()
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(red: 0.839, green: 0.839, blue: 0.839), lineWidth: 2)
                    .accessibilityLabel("TOTAL: \(totalValue)")
            )
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.882, green: 0.882, blue: 0.882))
            )
            .padding(.horizontal)
            .onTapGesture(perform: onTap)
        }
    }
}
