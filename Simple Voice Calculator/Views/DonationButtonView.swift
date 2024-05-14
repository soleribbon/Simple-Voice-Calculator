//
//  DonationButtonView.swift
//  Simple Voice Calculator
//
//  Created by Ravi Heyne on 14/05/24.
//

import SwiftUI

struct DonationButton: View {
    let title: String
    let color: Color
    let isProcessing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
                    .frame(height: 50)

                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .bold()
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .padding(.horizontal, 16)  
                }
            }
            .frame(maxWidth: .infinity)
        }
        .animation(.easeInOut(duration: 0.2), value: isProcessing)
    }
}
