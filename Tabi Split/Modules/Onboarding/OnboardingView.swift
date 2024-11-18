//
//  OnboardingView.swift
//  Tabi Split
//
//  Created by Elian Richard on 18/11/24.
//

import SwiftUI

private struct OnboardingData: Identifiable {
    var id = UUID()
    var title: String
    var description: String
}

struct OnboardingView: View {
    @Environment(Routes.self) private var routes
    
    @State private var isNextPressed = false
    @State private var scrollPosition: Int?
    @State private var currentIndex = 0
    @State private var isAutoScroll = false
    private let animationDuration: CGFloat = 0.5
    private let secondsPerSlide: CGFloat = 2.5
    
    
    private var data: [OnboardingData] = [
        OnboardingData(title: "Collaborate with your friends", description: "Create an event and invite others to collaborate with them."),
        OnboardingData(title: "Quickly add expenses", description: "Add expenses into your event within less than 5 mins, with OCR or manually."),
        OnboardingData(title: "Settle with ease...", description: "No more unnecessary settlements with automated & optimized calculation."),
        //        TEMPORARILY DISABLED: ONBOARDING REMINDER FEATURE
        //        OnboardingData(title: "...and hassle-free!", description: "Only one tap to remind your friends and check their payment info."),
        OnboardingData(title: "Start Your Journey\nwith Tabi now!", description: ""),
    ]
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    print("navigate to input name")
                } label: {
                    Text("Enter as Guest")
                        .font(.tabiBody)
                        .foregroundStyle(.textGrey)
                }
                .opacity(isNextPressed ? 1 : 0)
                .disabled(!isNextPressed)
                Spacer()
            }
            .padding(.horizontal)
            Spacer()
            VStack (spacing: .spacingXLarge) {
                if !isNextPressed {
                    OnboardingDetailView(title: "Welcome to Tabi!", description: "The solution to record and settle your shared expenses with your groups.")
                } else {
                    ScrollView (.horizontal) {
                        HStack (spacing: 0) {
                            ForEach (0..<data.count, id:\.self) { index in
                                let onboardingData = data[index]
                                OnboardingDetailView(data: onboardingData)
                                    .containerRelativeFrame(.horizontal)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollPosition(id: $scrollPosition)
                    .scrollIndicators(.hidden)
                    .scrollTargetBehavior(.paging)
                    .onChange(of: scrollPosition) {
                        guard let scrollPosition else { return }
                        withAnimation {
                            currentIndex = scrollPosition
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + secondsPerSlide, execute: {
                            if isAutoScroll {
                                changeSlide()
                            }
                        })
                    }}
                
                HStack (spacing: .spacingXSmall) {
                    ForEach (Array(data.enumerated()), id:\.offset) { index in
                        Button {
                            isAutoScroll = false
                            withAnimation {
                                scrollPosition = index.offset
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(index.offset == currentIndex ? .buttonDarkBlue : .buttonBlue)
                                .frame(width: index.offset == currentIndex ? 24 : 10 , height: 10)
                                .opacity(isNextPressed ? 1 : 0)
                        }
                    }
                }
            }
            Spacer()
            VStack (spacing: .spacingRegular) {
                CustomButton(text: isNextPressed ? "Sign In" : "Next", animation: .default) {
                    withAnimation {
                        if (isNextPressed) {
                            routes.navigate(to: .LoginView)
                        } else {
                            scrollPosition = 0
                            isNextPressed = true
                            isAutoScroll = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + secondsPerSlide, execute: {
                                changeSlide()
                            })
                        }
                    }
                }
                .zIndex(10)
                if isNextPressed {
                    CustomButton(text: "Sign Up", type: .secondary) {
                        routes.navigate(to: .RegisterView)
                    }
                }
            }
            .frame(height: 123, alignment: .bottom)
            .padding(.horizontal)
        }
        .padding(.vertical)
        .navigationBarBackButtonHidden(true)
    }
    private func changeSlide () {
        guard let scrollPosition else { return }
        withAnimation (.linear(duration: animationDuration)) {
            if scrollPosition < data.count - 1 {
                self.scrollPosition = scrollPosition + 1
            } else {
                self.scrollPosition = 0
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(Routes())
}

private struct OnboardingDetailView: View {
    var title: String
    var description: String
    
    init(title: String, description: String) {
        self.title = title
        self.description = description
    }
    
    init(data: OnboardingData) {
        self.title = data.title
        self.description = data.description
    }
    
    var body: some View {
        VStack (spacing: .spacingLarge) {
            Image(.initialOnboarding)
                .resizable()
                .scaledToFit()
                .frame(width: 300)
            VStack (spacing: .spacingTight) {
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(.tabiTitle)
                Text(description)
                    .multilineTextAlignment(.center)
                    .font(.tabiHeadline)
                    .padding(.horizontal)
            }
        }
    }
}
