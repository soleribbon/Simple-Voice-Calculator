//
//  AboutView.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 4/27/23.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            ScrollView (.vertical){
                VStack (alignment: .leading){
                    
                    
                    HStack(alignment: .center){
                        Image("Mic")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .font(.title2)
                            .cornerRadius(10)
                            .padding(.vertical)
                            .padding(.horizontal, 6)
                        VStack (alignment: .leading) {
                            Text("About Simple Voice Calculator")
                                .font(.title2)
                                .padding(.vertical, 6)
                            .bold()
                        }
                        Spacer()
                        
                    }.padding(.horizontal, 10)
                    
                    Text("By VITO SOFTWARE")
                        .font(.caption)
                        .opacity(0.4)
                        .padding(.horizontal)
                    
                   
                }
                Text("In a world forever on the move, the seed of Simple Voice Calculator was planted with the simple goal of making math accessible for everyone, everywhere. We (the creators) saw that some people struggled to type out long equations, while others had difficulty seeing and tapping small numbers on their screens. These observations sparked an idea. We decided to create an app that transcended traditional input methods, one that used the simplicity of human voice to solve equations. Thus, Simple Voice Calculator was born, a testament to human ingenuity and the power of voice. Designed to understand and solve basic equations, it also allows for instant editing, embodying the notion that math is a flexible, living language. This app is not just a tool, but a story of making math simple, accessible, and inclusive.").padding()
            }
        }
        .padding()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)

    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
