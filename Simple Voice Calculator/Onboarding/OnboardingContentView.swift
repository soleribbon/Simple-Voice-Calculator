//
//  OnboardingContentView.swift
//  Simple Voice Calculator
//
//  Created by Ravi  on 5/1/23.
//

import SwiftUI
struct Feature: Identifiable {
    var id = UUID()
    var title: String
    var buttonText: String
    var image: String
}


let features = [
    Feature(title: "Welcome to \nSimple Voice Calculator", buttonText: "Quick Setup", image: "Mic"),
    Feature(title: "This is where the magic happens.", buttonText: "Continue", image: "homeIntro"),
    Feature(title: "Easily edit any component of your equation.", buttonText: "Continue", image: "editOnTap"),
    Feature(title: "'Invalid Equation' means your input was invalid. Check your equation.", buttonText: "Continue", image: "invalidEquation"),
    Feature(title: "Help is always available.", buttonText: "Continue", image: "helpAlways"),
    Feature(title: "Now, time to calculate.", buttonText: "Get Started", image: "")
]


struct OnboardingContentView: View {
    @AppStorage("isOnboarding") var isOnboarding: Bool?
    var feature: Feature
    @Binding var currentPage: Int
    var featureIndex: Int
    
    var isLastFeature: Bool {
        feature.id == features.last?.id
    }
    var body: some View {
        
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(#colorLiteral(red: 0.14509804546833038, green: 0.2823529541492462, blue: 0.7058823704719543, alpha: 1)), location: 0),
                    .init(color: Color(#colorLiteral(red: 0.11380210518836975, green: 0.18283073604106903, blue: 0.3958333432674408, alpha: 1)), location: 1)]),
                startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17),
                endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
            .edgesIgnoringSafeArea(.all)
            
            if !isLastFeature {
                VStack {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(feature.image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                .padding()
                            Spacer()
                        }
                        Spacer()
                        Text(feature.title)
                            .bold()
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color(red: 0.129, green: 0.231, blue: 0.537), lineWidth: 2)
                        
                        
                        
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.0725, green: 0.166, blue: 0.458))
                        
                            .shadow(color: Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)), radius:3.78, x:0, y:1.89)
                    )
                    .padding()
                    //button and skip vstack
                    VStack (spacing: 6){
                        Button(action: {
                            withAnimation{
                                currentPage = featureIndex + 1
                            }
                            
                            
                        }, label: {
                            HStack{
                                Text(feature.buttonText)
                                Image(systemName: "arrow.right")
                            }
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(.blue)
                            .cornerRadius(10)
                        })
                        Text("or")
                            .bold()
                            .font(.body)
                            .foregroundColor(.white)
                            .opacity(0.5)
                        
                        
                        Button(action: {
                            isOnboarding = false
                        }, label: {
                            Text("Skip Introduction")
                                .bold()
                                .underline()
                                .foregroundColor(.white)
                        })
                        
                        
                        Spacer().frame(height: 10)
                    }//end button and skip vstack
                    
                    
                    
                    
                    
                    
                }
            } else {
                //last ending view
                VStack{
                    VStack{
                        HStack{
                            Spacer()
                            Text("Important Notes")
                                .bold()
                                .font(.title)
                                .foregroundColor(.white)
                            
                            Spacer()
                        }.padding()
                        VStack (alignment: .center){
                            Text("Only **+ - × ÷**  are supported")
                                .multilineTextAlignment(.center)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.10000000149011612)))
                                )
                            //end of one
                            Text("After pressing 'Stop Talking' your dictated equation will be automatically appended to the end of the input field.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.10000000149011612)))
                                )
                            //end of one
                            Text("While voice dictation is enabled, you are unable to manually edit the input field.")
                                .font(.body)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.10000000149011612)))
                                )
                            //end of one
                            
                            Text("Ensure no alphabetical letters are included in your input.")
                                .font(.body)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.10000000149011612)))
                                )
                            //end of one
                            Spacer()
                            Text("...and finished 🎉")
                                .bold()
                                .font(.title2)
                                .foregroundColor(.white)
                            Text(feature.title)
                                .bold()
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .multilineTextAlignment(.center)
                            Spacer()
                            Button(action: {
                                isOnboarding = false
                            }, label: {
                                HStack{
                                    Text(feature.buttonText)
                                }
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .background(.blue)
                                .cornerRadius(10)
                            })
                            
                        }.padding()
                        
                        
                        
                        
                        
                    }
                    
                }
                .padding()
            }
            
            
        }
        
        
        
    }
}


