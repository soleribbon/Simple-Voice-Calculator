//
//  AboutView.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 4/27/23.


import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationView {
            VStack {
                VStack (alignment: .center){
                    
                    
                    Image("aboutImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .font(.title2)
                    
                    Text("Our Story")
                        .font(.title2.weight(.bold))
                        .padding(.vertical, 4)
                    Text("MADE BY VITO SOFTWARE")
                        .font(.caption)
                        .opacity(0.5)
                    
                    
                }
                
                List {
                    Text("Simple Voice Calculator began with a clear purpose: to make math **easier and more accessible** for everyone. Recognizing that typing complex equations or tapping small buttons can be challenging—especially on smaller screens—we developed an intuitive alternative. With easy voice input and instant editing capabilities, Simple Voice Calculator offers a natural and inclusive experience, transforming the way we interact with math in everyday life.")
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .fontWeight(.regular)
                        .padding()
                    
                }.listStyle(.automatic)
                
            }
        }
        
        
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
