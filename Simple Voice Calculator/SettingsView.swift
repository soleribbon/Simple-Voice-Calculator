import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var helpExpanded = false
    @State private var privacyExpanded = false

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Quick Help")) {
                    DisclosureGroup(isExpanded: $helpExpanded) {

                        VStack(alignment: .leading) {
                            Text("**What math operators are supported?**")
                                .font(.body)
                                .padding(.vertical)
                            Text("Currently supported operators: + - × ÷")
                                .font(.body)
                                .padding(.bottom)
                        }
                       
                        
                        VStack(alignment: .leading) {
                            Text("**What does 'Invalid Equation' mean?**")
                                .font(.body)
                                .padding(.vertical)
                            Text("Invalid Equation is presented when the textfield contains characters that are not valid in a mathematical equation or not currently supported.").font(.body)
                                .padding(.bottom)

                        }
                       
                        
                        VStack(alignment: .leading) {
                            Text("**How do I edit my voice input?**")
                                .font(.body)
                                .padding(.vertical)
                            Text("Stop voice input. Then, you can edit any component of your equation in the 'Equation Components' section. Just tap you desired components and it will be selected in your textfield.")
                                .font(.body)
                                .padding(.bottom)

                        }
                        
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.accentColor)
                            Text("FAQ")
                                
                        }
                    }
                }


                Section(header: Text("About & Contact")) {
                    NavigationLink(destination: AboutView())
                                   {
                            HStack {
                                Text("ℹ️")
                                    .foregroundColor(.accentColor)
                                Text("About Simple Voice Calculator")
                                Spacer()
                            }
                            
                            
                        
                    }
                    Link(destination: URL(string: "https://www.raviheyne.com")!, label: {
                        HStack {
                            Text("💌")
                                .foregroundColor(.accentColor)
                            Text("Contact Us")
                        }
                    })
                    Link(destination: URL(string: "https://www.raviheyne.com")!) {
                        HStack {
                           Text("☕️")
                                .foregroundColor(.accentColor)
                            Text("Buy developer a coffee")
                        }
                    }
                }


                
                Section(header: Text("Privacy")) {
                    DisclosureGroup(isExpanded: $privacyExpanded) {
                        Text("We take privacy so seriously that we don't even collect any information at all! Once a calculation is cleared, it's gone forever.")
                        Text("*Speech data is sent to Apple to ensure transcription accuracy")
                            .font(.caption2)
                            .opacity(0.4)
                    } label: {
                        HStack {
                            Image(systemName: "shield")
                                .foregroundColor(.accentColor)
                            Text("Privacy")
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Version")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("1.0.0 (beta)")
                            .font(.body)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
