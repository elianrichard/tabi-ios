//
//  OnboardingView.swift
//  Tabi Split
//
//  Created by Elian Richard on 18/11/24.
//

import SwiftUI
import Lottie

private struct OnboardingData: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var animationName: String
    var imageSize: CGFloat?
}

struct OnboardingView: View {
    @Environment(Routes.self) private var routes
    
    @State private var isNextPressed = false
    @State private var scrollPosition: Int?
    @State private var currentIndex = 0
    @State private var isDragging = false
    @State private var isAutoScroll = false
    @State private var timer: Timer?
    private let animationDuration: CGFloat = 0.5
    private let secondsPerSlide: CGFloat = 5
    
    
    private var data: [OnboardingData] = [
        OnboardingData(title: "Collaborate with your friends", description: "Create an event and invite others to collaborate with them.", animationName: "OnboardingInvite", imageSize: 300),
        OnboardingData(title: "Quickly add expenses", description: "Add expenses into your event within less than 5 mins, with OCR or manually.", animationName: "OnboardingScan", imageSize: 500),
        OnboardingData(title: "Settle with ease...", description: "No more unnecessary settlements with automated & optimized calculation.", animationName: "OnboardingOptimization", imageSize: 300),
        //        TEMPORARILY DISABLED: ONBOARDING REMINDER FEATURE
        //        OnboardingData(title: "...and hassle-free!", description: "Only one tap to remind your friends and check their payment info."),
        OnboardingData(title: "Start Your Journey\nwith Tabi now!", description: "", animationName: "OnboardingWelcome2"),
    ]
    
    
    var body: some View {
        let dragGesture = DragGesture()
            .onChanged({ _ in
                isDragging = true
            })
            .onEnded { _ in
                isDragging = false
            }
        let pressGesture = LongPressGesture(minimumDuration: 0)
            .onChanged({ _ in
                isDragging = true
                isAutoScroll = false
            })
            .onEnded { _ in
                isDragging = false
                isAutoScroll = true
            }
        let combined = pressGesture.sequenced(before: dragGesture)
        
        VStack {
            HStack {
                Spacer()
                Button {
                    scrollPosition = 3
                } label: {
                    Text("Skip")
                        .font(.tabiBody)
                        .foregroundStyle(.textGrey)
                }
                .opacity((isNextPressed && scrollPosition != 3) ? 1 : 0)
                .disabled(!(isNextPressed && scrollPosition != 3))
            }
            .padding(.horizontal)
            VStack (spacing: .spacingXLarge) {
                if !isNextPressed {
                    OnboardingDetailView(title: "Welcome to Tabi!", description: "The solution to record and settle your shared expenses with your groups.", animationName: "OnboardingWelcome")
                        .frame(maxWidth: .infinity)
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
                        
                        if let pos = self.scrollPosition{
                            if pos == 3 {
                                timer?.invalidate()
                            }
                        }
                        timer?.fireDate = Date(timeIntervalSinceNow: secondsPerSlide)
                    }
                    .gesture(combined)
                }
                
                HStack (spacing: .spacingXSmall) {
                    ForEach (Array(data.enumerated()), id:\.offset) { index in
                        Button {
                            withAnimation {
                                scrollPosition = index.offset
                                isAutoScroll = false
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(index.offset == currentIndex ? .buttonDarkBlue : .buttonBlue)
                                .frame(width: index.offset == currentIndex ? 24 : 10 , height: 10)
                                .opacity(isNextPressed ? 1 : 0)
                        }
                        .padding(.bottom)
                    }
                }
            }
            VStack (spacing: .spacingRegular) {
                CustomButton(text: scrollPosition == 3 ? "Sign In" : "Next", animation: .default) {
                    withAnimation {
                        if let pos = scrollPosition {
                            if pos == 3 {
                                routes.navigate(to: .LoginView)
                            }else{
                                scrollPosition = pos + 1
                            }
                        } else {
                            scrollPosition = 0
                            isNextPressed = true
                            isAutoScroll = true
                            timer = Timer.scheduledTimer(withTimeInterval: secondsPerSlide, repeats: true, block: { Timer in
                                if isAutoScroll{
                                    changeSlide()
                                }
                            })
                        }
                    }
                }
                .zIndex(10)
                if scrollPosition == 3 {
                    CustomButton(text: "Sign Up", type: .secondary) {
                        routes.navigate(to: .RegisterView)
                    }
                }
            }
            .frame(height: 123, alignment: .bottom)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
        .navigationBarBackButtonHidden(true)
    }
    
    private func changeSlide () {
        guard let scrollPosition, !isDragging else { return }
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
    var animationName: String
    var imageSize: CGFloat?
    
    init(title: String, description: String, animationName: String, imageSize: CGFloat? = nil) {
        self.title = title
        self.description = description
        self.animationName = animationName
        self.imageSize = imageSize
    }
    
    init(data: OnboardingData) {
        self.title = data.title
        self.description = data.description
        self.animationName = data.animationName
        self.imageSize = data.imageSize
    }
    
    var body: some View {
        VStack (spacing: .spacingMedium) {
            LottieView(animation: .named(animationName))
                .looping()
                .resizable()
                .padding(-10)
                .frame(maxWidth: imageSize == nil ? .infinity : imageSize)
                .scaledToFit()
            VStack (spacing: .spacingTight) {
                Text(title)
                    .multilineTextAlignment(.center)
                    .font(.tabiTitle)
                Text(description)
                    .multilineTextAlignment(.center)
                    .font(.tabiHeadline)
                    .padding(.horizontal, .spacingLarge)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
