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
    Feature(title: "Welcome to \nSimple Voice Calculator", buttonText: "Quick Setup", image: "aboutImage"),
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
    
    var actualIntro: Bool
    var featureIndex: Int
    
    // Animation state
    @State private var buttonScale: CGFloat = 1.0
    
    var isLastFeature: Bool {
        feature.id == features.last?.id
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(#colorLiteral(red: 0.14509804546833038, green: 0.2823529541492462, blue: 0.7058823704719543, alpha: 1)), location: 0),
                    .init(color: Color(#colorLiteral(red: 0.11380210518836975, green: 0.18283073604106903, blue: 0.3958333432674408, alpha: 1)), location: 1)]),
                startPoint: UnitPoint(x: 0.5, y: -3.0616171314629196e-17),
                endPoint: UnitPoint(x: 0.5, y: 0.9999999999999999))
            .edgesIgnoringSafeArea(.all)
            
            // Regular feature view
            if !isLastFeature {
                VStack {
                    Spacer(minLength: 30)
                    
                    // Content card
                    contentCard
                        .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                    
                    // Navigation buttons
                    navigationButtons
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                }
            } else {
                // Last feature (final screen)
                finalScreenView
            }
        }
        .accessibilityLabel("Onboarding screen \(featureIndex + 1) of \(features.count)")
        .accessibilityHint("Swipe left to go to the next screen, or use the buttons below")
    }
    
    // MARK: - Content Card
    private var contentCard: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 20)
            
            // Feature image
            if !feature.image.isEmpty {
                Image(feature.image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .accessibilityLabel("Illustration for \(feature.title)")
            }
            
            Spacer(minLength: 4)
            
            // Feature title
            Text(LocalizedStringKey(feature.title))
                .bold()
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHeading(.h1)
            
            Spacer(minLength: 30)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.0725, green: 0.166, blue: 0.458))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: 16) {
            // Next button
            Button(action: {
                // Haptic feedback
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()

                // Just shrink the button
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 0.95
                }

                // Navigate after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation {
                        currentPage = featureIndex + 1

                        // Reset button scale
                        buttonScale = 1.0
                    }
                }
            }) {
                // Simple centered layout with text and arrow
                HStack(spacing: 8) {
                    Text(LocalizedStringKey(feature.buttonText))
                        .bold()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                .scaleEffect(buttonScale)
            }
            .accessibilityHint("Advances to the next screen")

            
            // Skip option
            if actualIntro {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 6) {
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            isOnboarding = false
                        }) {
                            Text("Skip Introduction")
                                .bold()
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .underline()
                                .padding(.vertical, 8)
                        }
                        .accessibilityHint("Skips the introduction and goes directly to the calculator")
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Final Screen
    private var finalScreenView: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    Text("Important Notes")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        .accessibilityHeading(.h1)
                    
                    // Important notes
                    noteCard("Only **+ - × ÷ %** are supported")
                    
                    noteCard("After pressing 'Stop Talking', your dictated equation will be added to the end of the input field.")
                    
                    noteCard("While voice dictation is enabled, you are unable to manually edit the input field.")
                    
                    noteCard("Ensure no alphabetical letters are included in your input.")
                    
                    Spacer(minLength: 20)
                    
                    // Final message
                    Text(LocalizedStringKey(feature.title))
                        .bold()
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.vertical)
                        .accessibilityHeading(.h2)
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.0725, green: 0.166, blue: 0.458))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            
            // Get Started button
            Button(action: {
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
                withAnimation {
                    isOnboarding = false
                }
            }) {
                Text(LocalizedStringKey(feature.buttonText))
                    .bold()
                    .foregroundColor(.white)
                    .padding(.vertical, 24) // More vertical padding
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
            .accessibilityHint("Completes the introduction and opens the calculator")
        }
        .padding(.vertical)
    }
    
    // Helper function to create note cards
    private func noteCard(_ text: String) -> some View {
        Text(LocalizedStringKey(text))
            .font(.system(size: 16))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.12))
            )
            .padding(.horizontal, 12)
    }
}

