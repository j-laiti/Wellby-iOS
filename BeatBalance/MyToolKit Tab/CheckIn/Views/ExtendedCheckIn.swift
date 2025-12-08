//
//  ExtendedCheckIn.swift
//  BeatBalance
//
//  Created by Justin Laiti on 10/27/24.
//

import SwiftUI

struct ExtendedCheckIn: View {
    @ObservedObject var checkInManager: CheckInManager
    @EnvironmentObject var userManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedMood: [String] = []
    @Binding var mood: String
    @Binding var relaxedSlider: Double
    @Binding var alertSlider: Double
    
    @State private var selectedReason: [String] = []
    @Binding var customReason: String
    
    @State private var selectedAction: [String] = []
    @Binding var customAction: String
    
    @Binding var showExtendedCheckIn: Bool
    
    var linkedToRecording: Bool
    
    var isFormValid: Bool {
        !mood.isEmpty || !selectedMood.isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                MoodSelectionView(selectedMood: $selectedMood, mood: $mood, colorScheme: colorScheme)

                SliderInputView(title: "How relaxed are you feeling? 🧘🏽‍♂️", value: $relaxedSlider)
                SliderInputView(title: "How alert are you feeling? 😳", value: $alertSlider)
                
                MoodReasonView(selectedReason: $selectedReason, customReason: $customReason, colorScheme: colorScheme)
                
                NextActionView(selectedAction: $selectedAction, customAction: $customAction, colorScheme: colorScheme)
                
                Button {
                    let moodString = selectedMood.joined(separator: ", ")
                    let reasonString = selectedReason.joined(separator: ", ")
                    let actionString = selectedAction.joined(separator: ", ")
                    
                    let moodSelected = mood.isEmpty ? moodString : (moodString.isEmpty ? mood : moodString + ", " + mood)
                    let reasonSelected = customReason.isEmpty ? reasonString : (reasonString.isEmpty ? customReason : reasonString + ", " + customReason)
                    let actionSelected = customAction.isEmpty ? actionString : (actionString.isEmpty ? customAction : actionString + ", " + customAction)
                    
                    if alertSlider == 0 {
                        alertSlider += 1
                    }
                    
                    if relaxedSlider == 0 {
                        relaxedSlider += 1
                    }
                    
                    // save check in data to firebase
                    if let userId = userManager.currentUser?.id {
                        checkInManager.saveCheckinData(
                            checkIn: CheckInData(
                                mood: moodSelected,
                                alertness: Int(alertSlider),
                                calmness: Int(relaxedSlider),
                                moodReason: reasonSelected,
                                nextAction: actionSelected,
                                date: Date(),
                                isLinkedToRecording: linkedToRecording
                            ),
                            userId: userId)
                    }
                    
                    // Reset values after saving
                    selectedMood = []
                    selectedReason = []
                    selectedAction = []
                    mood = ""
                    alertSlider = 0.0
                    relaxedSlider = 0.0
                    customReason = ""
                    customAction = ""
                    
                    // navigate??
                    showExtendedCheckIn.toggle()
                    
                } label: {
                    Text("Finish Check-in")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding(.horizontal, 30)
                .disabled(!isFormValid)
                
            }
        }
    }
    
    struct MoodSelectionView: View {
        @Binding var selectedMood: [String]
        @Binding var mood: String
        var colorScheme: ColorScheme
        
        var body: some View {
            VStack {
                Text("How are you feeling today?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                HStack {
                    EmojiButton(emoji: "😄", description: "happy", selectedArray: $selectedMood)
                    EmojiButton(emoji: "☺️", description: "calm", selectedArray: $selectedMood)
                    EmojiButton(emoji: "😣", description: "stressed", selectedArray: $selectedMood)
                    EmojiButton(emoji: "😐", description: "bored", selectedArray: $selectedMood)
                    EmojiButton(emoji: "🥱", description: "tired", selectedArray: $selectedMood)
                }
                .padding(.top)

                TextField("🫥 Other", text: $mood)
                    .padding(10)
                    .background(
                        Group {
                            if colorScheme == .light {
                                Color(.systemGray6)
                            } else {
                                Color(.systemGray5)
                            }
                        }
                    )
                    .cornerRadius(10)
                    .frame(width: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(mood.isEmpty ? Color.clear : Color.blue, lineWidth: 2)
                    )
            }
        }
    }

    struct SliderInputView: View {
        var title: String
        @Binding var value: Double
        var range: ClosedRange<Double> = 1...5

        var body: some View {
            VStack(alignment: .center) {
                Text(title)
                    .font(.title3)
                Slider(value: $value, in: range, step: 1)
                    .padding(.horizontal, 25)
                    .accentColor(.blue)
            }
            .padding()
        }
    }

    struct MoodReasonView: View {
        @Binding var selectedReason: [String]
        @Binding var customReason: String
        var colorScheme: ColorScheme

        var body: some View {
            VStack {
                Text("What's affecting your mood?")
                    .font(.title3)

                HStack {
                    EmojiButton(emoji: "📚", description: "school", selectedArray: $selectedReason)
                    EmojiButton(emoji: "🗣️", description: "social life", selectedArray: $selectedReason)
                    EmojiButton(emoji: "🏠", description: "family", selectedArray: $selectedReason)
                    EmojiButton(emoji: "🛌", description: "sleep", selectedArray: $selectedReason)
                }

                TextField("Other", text: $customReason)
                    .padding(10)
                    .background(
                        Group {
                            if colorScheme == .light {
                                Color(.systemGray6)
                            } else {
                                Color(.systemGray5)
                            }
                        }
                    )
                    .cornerRadius(10)
                    .frame(width: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(customReason.isEmpty ? Color.clear : Color.blue, lineWidth: 2)
                    )
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    struct NextActionView: View {
        @Binding var selectedAction: [String]
        @Binding var customAction: String
        var colorScheme: ColorScheme

        var body: some View {
            VStack {
                Text("Is there something you would like to do next?")
                    .font(.title3)

                VStack {
                    Text("In-App Actions")
                        .font(.subheadline)
                        .foregroundStyle(.gray)

                    HStack {
                        EmojiButton(emoji: "✍️", description: "plan", selectedArray: $selectedAction)
                        EmojiButton(emoji: "😮‍💨", description: "breathe", selectedArray: $selectedAction)
                        EmojiButton(emoji: "♥️", description: "HRV", selectedArray: $selectedAction)
                        EmojiButton(emoji: "💬", description: "chat", selectedArray: $selectedAction)
                    }
                }
                .padding(5)

                VStack {
                    Text("Other Actions")
                        .font(.subheadline)
                        .foregroundStyle(.gray)

                    HStack {
                        EmojiButton(emoji: "🫂", description: "talk with someone", selectedArray: $selectedAction)
                        EmojiButton(emoji: "🚦", description: "take a break", selectedArray: $selectedAction)
                        EmojiButton(emoji: "⛰️", description: "get outside", selectedArray: $selectedAction)
                        EmojiButton(emoji: "🚶🏻‍♀️‍➡️", description: "move your body", selectedArray: $selectedAction)
                    }
                }
                .padding(5)

                TextField("Other", text: $customAction)
                    .padding(10)
                    .background(
                        Group {
                            if colorScheme == .light {
                                Color(.systemGray6)
                            } else {
                                Color(.systemGray5)
                            }
                        }
                    )
                    .cornerRadius(10)
                    .frame(width: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(customAction.isEmpty ? Color.clear : Color.blue, lineWidth: 2)
                    )
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

}

