//
//  BreathTempo.swift
//  BeatBalance
//
//  Created by Justin Laiti on 2/15/24.
//

import SwiftUI

struct BreathPacer: View {
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var userManager: AuthManager
    
    @State private var scale: CGFloat = 1.0
    @State private var breathInTime: Double = 4
    @State private var breathOutTime: Double = 4
    @State private var hold1Time: Double = 2
    @State private var hold2Time: Double = 2
    @State private var breathStatus: String = "Breath In"
    @State private var selectedExercise: BreathingExercise = .custom
    @State private var animationToken: UUID = UUID()
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text(breathStatus)
                .font(.title)
                .fontWeight(.medium)
                .transition(.opacity.combined(with: .slide))
                .animation(.easeInOut, value: breathStatus)
                .padding()
            
            
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [settings.primaryColor, settings.primaryColor.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 75, height: 75)
                .foregroundStyle(.purple)
                .scaleEffect(scale)
                .frame(width: 200, height: 250)
            
            Spacer()
            
            Picker("Selected Exercise", selection: $selectedExercise) {
                ForEach(BreathingExercise.allCases) { exercise in
                    Text(exercise.rawValue).tag(exercise)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: selectedExercise) { newValue in
                setExerciseTimes()
            }
            
            VStack {
                sliderView(title: "Breath In", time: $breathInTime)
                sliderView(title: "Hold One", time: $hold1Time)
                sliderView(title: "Breath Out", time: $breathOutTime)
                sliderView(title: "Hold two", time: $hold2Time)
            }
            .padding()
            .padding(.horizontal)
            
        }
        .onAppear {
            resetAndStartAnimation()
            userManager.viewDidAppear(screen: "Breath Pacer")
        }
        .onChange(of: selectedExercise) { _ in
            setExerciseTimes() // Set the times based on the new exercise
            resetAndStartAnimation() // Then reset and restart the animation
        }
    }

    
    func sliderView(title: String, time: Binding<Double>) -> some View {
        HStack {
            Text(title)
                .frame(width: 90)
                .foregroundStyle(.secondary)
            Slider(value: time, in: 1...10, step: 0.5)
                .tint(settings.primaryColor)
            Text("\(time.wrappedValue, specifier: "%.1f")s")
                .foregroundStyle(.secondary)
        }
    }
    
    func animatedBreath(currentToken: UUID) {
        // Only proceed if the token is still current
        guard animationToken == currentToken else { return }

        // Start with breathing in
        breathStatus = "Breathe In"
        withAnimation(.easeInOut(duration: breathInTime)) {
            scale = 3.0
        }

        // Schedule the rest of the animation sequence, checking the token each time
        DispatchQueue.main.asyncAfter(deadline: .now() + breathInTime) {
            guard self.animationToken == currentToken else { return }
            self.breathStatus = "Hold"

            DispatchQueue.main.asyncAfter(deadline: .now() + self.hold1Time) {
                guard self.animationToken == currentToken else { return }
                self.breathStatus = "Breathe Out"
                withAnimation(.easeInOut(duration: self.breathOutTime)) {
                    self.scale = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + self.breathOutTime) {
                    guard self.animationToken == currentToken else { return }
                    self.breathStatus = "Hold"

                    // Schedule the next cycle, if the token is still valid
                    DispatchQueue.main.asyncAfter(deadline: .now() + self.hold2Time) {
                        guard self.animationToken == currentToken else { return }
                        self.animatedBreath(currentToken: currentToken)
                    }
                }
            }
        }
    }
    
    func resetAndStartAnimation() {
        // Update the token, which cancels any ongoing animation sequences
        animationToken = UUID()

        // Reset necessary states if needed
        scale = 1.0  // Reset scale to initial value
        breathStatus = "Breathe In"  // Reset initial breath status

        // Restart the animation with the new token
        animatedBreath(currentToken: animationToken)
    }
    
    enum  BreathingExercise: String, CaseIterable, Identifiable {
        case custom = "Custom"
        case boxBreathing = "Box Breathing"
        case resonantBreathing = "Resonant Breathing"
        case deepBreathing = "Deep Breathing"
        
        var id: String { self.rawValue }
    }
    
    func setExerciseTimes() {
        switch selectedExercise {
        case .custom:
            breathInTime = 5
            hold1Time = 1
            breathOutTime = 5
            hold2Time = 1
        case .boxBreathing:
            breathInTime = 4
            hold1Time = 4
            breathOutTime = 4
            hold2Time = 4
        case .resonantBreathing:
            breathInTime = 5.5
            hold1Time = 0
            breathOutTime = 5.5
            hold2Time = 0
        case .deepBreathing:
            breathInTime = 4
            hold1Time = 6
            breathOutTime = 8
            hold2Time = 6
        }
    }
    
    
}


#Preview {
    BreathPacer()
}
