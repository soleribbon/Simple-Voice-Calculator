//
//  SettingsView.swift
//  Simple Voice Calculator Watch Edition Watch App
//
//  Created by Ravi Heyne on 17/07/24.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Image(systemName: "headphones")
                        .font(.system(size: 30))
                    Text("To play audio, connect Bluetooth headphones to your Apple Watch.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)

                }
                .padding()
                .background(.gray)
                .cornerRadius(10)

                VStack {
                    Text("VITO SOFTWARE")
                    HStack {
                        Text("Version")
                        Text(Bundle.main.releaseVersionNumber ?? "1.0")
                    }

                }
                .font(.footnote)
                .opacity(0.5)


            }
        }
    }
}

#Preview {
    SettingsView(isPresented: .constant(true))
}
extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

