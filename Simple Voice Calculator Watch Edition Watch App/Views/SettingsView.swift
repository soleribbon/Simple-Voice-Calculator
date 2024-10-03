import SwiftUI

struct SettingsView: View {
    //    @Binding var isPresented: Bool
    @ObservedObject var storeManager = StoreManager.shared
    @AppStorage("shouldSpeakTotal") var shouldSpeakTotal: Bool = false
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 10) {
                    // Tip a Coffee Section
                    VStack {
                        Text("Tip a Coffee")
                            .multilineTextAlignment(.center)
                            .bold()
                        
                        VStack(spacing: 10) {
                            // First line: Tip 1 and 2 coffees
                            HStack(spacing: 10) {
                                // Tip 1 coffee
                                Button(action: {
                                    storeManager.purchaseProduct(withIdentifier: storeManager.productIdentifiers[0])
                                    
                                }) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .padding()
                                        .background(
                                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color(#colorLiteral(red: 0.2745098174, green: 0.7103391365, blue: 0.7148171769, alpha: 1))]),
                                                           startPoint: .bottom,
                                                           endPoint: .top)
                                            .clipShape(Capsule())
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Tip 2 coffees
                                Button(action: {
                                    storeManager.purchaseProduct(withIdentifier: storeManager.productIdentifiers[1])
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "cup.and.saucer.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                        Image(systemName: "cup.and.saucer.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    }
                                    .padding()
                                    .background(
                                        LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.7450980544, green: 0.3716002081, blue: 0.07450980693, alpha: 1)), Color(#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1))]),
                                                       startPoint: .top,
                                                       endPoint: .bottom)
                                        .clipShape(Capsule())
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Second line: Tip 3 coffees
                            Button(action: {
                                storeManager.purchaseProduct(withIdentifier: storeManager.productIdentifiers[2])
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "cup.and.saucer.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                    Image(systemName: "cup.and.saucer.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                    Image(systemName: "cup.and.saucer.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                }
                                .padding()
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.8522135615348816, green: 0.7158593535423279, blue: 0, alpha: 1)), Color(#colorLiteral(red: 0.7450980544, green: 0.4063578611, blue: 0.07450980693, alpha: 1))]),
                                                   startPoint: .top,
                                                   endPoint: .bottom)
                                    .clipShape(Capsule())
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.gray).opacity(0.25))
                    .cornerRadius(10)
                    
                    // Announce Total Toggle Section
                    VStack {
                        Toggle(isOn: $shouldSpeakTotal) {
                            Text("Announce Total")
                                .font(.footnote)
                        }
                        .toggleStyle(SwitchToggleStyle())
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.gray).opacity(0.25))
                    .cornerRadius(10)
                    
                    // App Information Section
                    VStack {
                        Text("VITO SOFTWARE")
                        HStack {
                            Text("Version")
                            Text(Bundle.main.releaseVersionNumber ?? "1.0")
                        }
                    }
                    .font(.footnote)
                    .opacity(0.5)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .onAppear {
                storeManager.startRequest(with: storeManager.productIdentifiers)
            }
            .alert(isPresented: $storeManager.showAlert) {
                Alert(title: Text(storeManager.alertMessage))
            }
        }
    }
}

#Preview {
    SettingsView()
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
