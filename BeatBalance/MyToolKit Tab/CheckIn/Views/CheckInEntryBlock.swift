//
//  CheckInEntryBlock.swift
//  BeatBalance
//
//  Created by Justin Laiti on 2/26/24.
//

import SwiftUI

struct CheckInEntryBlock: View {
    @StateObject private var checkInManager = CheckInManager()
    @EnvironmentObject var userManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    @Environment(\.colorScheme) var colorScheme
    
    var onHomeScreen = true
    
    @State private var mood: String = ""
    @State private var alertSelected: Int = 0
    @State private var calmSelected: Int = 0
    @State private var customReason: String = ""
    @State private var customAction: String = ""
    
    @State private var showExtendedCheckIn = false
    
    var isFormValid: Bool {
        !mood.isEmpty && alertSelected != 0 && calmSelected != 0
    }
    
    @State private var showingInfoAlert = false

    let alertness = ["_","1","2","3","4","5"]
    let calmness = ["_","1","2","3","4","5"]
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("I'm feeling:")
                        .bold()
                        .foregroundStyle(.primary)
                    
                    if onHomeScreen {
                        Button {
                            showingInfoAlert = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                        }
                        .alert("How to Check In", isPresented: $showingInfoAlert) {
                            Button("OK", role: .cancel) { }
                        }
                        message: {
                            Text("Enter a single emoji that represents your current mood. Then, select your level of alertness and calmness from 1-5, where 5 represents the most alert and calm.")
                        }
                    }
                    
                    Spacer()

                    if onHomeScreen {
                        NavigationLink {
                            CheckInTracker(checkInManager: checkInManager)
                        } label: {
                            Image(systemName: "chart.xyaxis.line")
                                .foregroundStyle(settings.primaryColor)
                        }
                    }

                }
                .padding(.horizontal, 10)
                
                Divider()
                
                HStack {
                    
                    Spacer()
                    MoodInputField(mood: $mood)
                    Spacer()
                    CheckInPicker(selection: $calmSelected, options: calmness, title: "Relaxed")
                    Spacer()
                    CheckInPicker(selection: $alertSelected, options: alertness, title: "Alert")
                    Spacer()
                    
                    if onHomeScreen {
                        Button {
                            if let userId = userManager.currentUser?.id {
                                checkInManager.saveCheckinData(
                                    checkIn: CheckInData(
                                        mood: mood,
                                        alertness: alertSelected,
                                        calmness: calmSelected,
                                        moodReason: "",
                                        nextAction: "",
                                        date: Date()
                                    ),
                                    userId: userId)
                                mood = ""
                                alertSelected = 0
                                calmSelected = 0
                            }
                        } label: {
                            VStack {
                                Image(systemName: "plus.circle")
                                    .padding(10)
                                    .foregroundStyle(isFormValid ? settings.primaryColor : .secondary)
                            }
                        }
                        .disabled(!isFormValid)
                    }

                }
                
                if onHomeScreen {
                    HStack {
                        Spacer()
                        
                        Button {
                            showExtendedCheckIn.toggle()
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        
                    }
                    .padding(.horizontal, 10)
                }
                
            }
            .padding(10)
            .background(
                Group {
                    if colorScheme == .light {
                        Color.white
                    } else {
                        Color.gray.opacity(0.3)
                    }
                })
            .cornerRadius(25)
            .shadow(radius: 5)
            .popover(isPresented: $showExtendedCheckIn) {
                // Extended check-in overlay
                VStack {
                    HStack {
                        Spacer()
                        Button(action: { showExtendedCheckIn = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .padding()
                        }
                    }
                    
                    ExtendedCheckIn(
                        checkInManager: checkInManager,
                        mood: $mood,
                        relaxedSlider: Binding(get: { Double(calmSelected) }, set: { calmSelected = Int($0) }),
                        alertSlider: Binding(get: { Double(alertSelected) }, set: { alertSelected = Int($0) }),
                        customReason: $customReason,
                        customAction: $customAction,
                        showExtendedCheckIn: $showExtendedCheckIn,
                        linkedToRecording: false
                    )
                }
            }
            
        }
    }
    
    struct MoodInputField: View {
        @Binding var mood: String
        var body: some View {
            VStack(alignment: .center) {
                TextField("🫥", text: $mood)
                    .font(.title)
                    .background(Color.clear)
                    .multilineTextAlignment(.center)
                    .onChange(of: mood) { newValue in
                        if newValue.count > 1 {
                            mood = String(newValue.prefix(1))
                        }
                    }
                    .frame(width: 60)

                Text("Mood")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .padding(5)
        }
    }

}
