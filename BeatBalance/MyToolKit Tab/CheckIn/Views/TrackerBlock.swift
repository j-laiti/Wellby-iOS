//
//  TrackerBlock.swift
//  BeatBalance
//
//  Created by Justin Laiti on 2/26/24.
//

import SwiftUI
import Charts

struct TrackerBlock: View {
    @ObservedObject var checkInManager: CheckInManager
    @EnvironmentObject var userManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedEntry: CheckInData?
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d/M"
        return formatter
    }()
    let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    let moodEmojiMap: [String: String] = [
        "happy": "😄",
        "calm": "☺️",
        "stressed": "😣",
        "bored": "😐",
        "tired": "🥱"
    ]
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                
                HStack(content: {
                    Button {
                        if let userId = userManager.currentUser?.id {
                            checkInManager.fetchPreviousEntries(userId: userId)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!checkInManager.canFetchPrevious)
                    .onTapGesture {
                        userManager.clickedOn(feature: "checkin tracker < button")
                    }
                    
                    Spacer()
                    Text("Mood")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(Color(red: 235/255, green: 195/255, blue: 138/255))
                    Spacer()
                    Button {
                        if let userId = userManager.currentUser?.id {
                            checkInManager.fetchNextEntries(userId: userId)
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!checkInManager.canFetchNext)
                })
                
                // Display only the first mood emoji for each entry
                HStack {
                    ForEach(checkInManager.checkInEntries) { entry in
                        
                        if let firstMood = entry.mood.components(separatedBy: ", ").first {
                            Text(moodEmojiMap[firstMood] ?? firstMood) // Display the first mood emoji or default to description
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                HStack {
                    Spacer()
                    Text("Alertness")
                        .foregroundStyle(settings.primaryColor)
                    Text(" & ")
                    Text("Calmness")
                        .foregroundStyle(settings.secondaryColor)
                    Spacer()
                }
                .font(.title2)
                .bold()
                
                Chart {
                    
                    ForEach(checkInManager.checkInEntries.indices, id: \.self) { index in
                        let entry = checkInManager.checkInEntries[index]
                        
                        PointMark(
                            x: .value("Entry", index),
                            y: .value("Calmness", entry.calmness)
                        )
                        .foregroundStyle(settings.secondaryColor)
                        
                        LineMark(
                            x: .value("Entry", index),
                            y: .value("Calmness", entry.calmness),
                            series: .value("Series", "Calmness")
                        )
                        .foregroundStyle(settings.secondaryColor)
                    }
                    
                    ForEach(checkInManager.checkInEntries.indices, id: \.self) { index in
                        let entry = checkInManager.checkInEntries[index]
                        
                        PointMark(
                            x: .value("Entry", index),
                            y: .value("Calmness", entry.alertness)
                        )
                        .foregroundStyle(settings.primaryColor.opacity(0.7))
                        
                        LineMark(
                            x: .value("Entry", index),
                            y: .value("Alertness", entry.alertness),
                            series: .value("Series", "Alertness")
                        )
                        .foregroundStyle(settings.primaryColor.opacity(0.7))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .stride(by: 1)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.secondary)
                        AxisTick()
                        AxisValueLabel()
                            .foregroundStyle(Color.secondary)
                    }
                }.chartYScale(domain: (1...5))
                    .chartXAxis {
                    }
                    .chartForegroundStyleScale(["Alertness": settings.primaryColor, "Calmness": settings.secondaryColor])
                    .chartLegend(.hidden)
                    .frame(height: 160)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 25)
                
                HStack {
                    ForEach(checkInManager.checkInEntries.indices, id: \.self) { index in
                        let entry = checkInManager.checkInEntries[index]
                        let formattedDate = dateFormatter.string(from: entry.date)
                        let formattedTime = timeFormatter.string(from: entry.date)
                        
                        VStack(alignment: .center) {
                            Text(formattedDate)
                                .font(.caption)
                                .padding(.horizontal, 4)
                            Text(formattedTime)
                                .font(.caption)
                                .padding(.horizontal, 4)
                        }
                        .foregroundStyle(.secondary)
                        .background(.blue.opacity(0.1)) // TODO: Change this format
                        .cornerRadius(8)
                        .onTapGesture {
                            selectedEntry = entry
                            userManager.clickedOn(feature: "mood check in entry detail button")
                        }
                        
                        if index < checkInManager.checkInEntries.count - 1 {
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal,10)
                
                Text("Tap on the date for full check-in details")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 5)
                    .padding(.horizontal)
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -100 {
                            // Swipe left
                            if checkInManager.canFetchNext {
                                if let userId = userManager.currentUser?.id {
                                    checkInManager.fetchNextEntries(userId: userId)
                                }
                            }
                        } else if value.translation.width > 100 {
                            // Swipe right
                            if checkInManager.canFetchPrevious {
                                if let userId = userManager.currentUser?.id {
                                    checkInManager.fetchPreviousEntries(userId: userId)
                                }
                            }
                        }
                        userManager.clickedOn(feature: "checkin tracker drag gesture")
                    }
            )
            .padding()
            
            // Detail view overlay when an entry is selected
            if let entry = selectedEntry {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .blur(radius: 5)
                    .onTapGesture {
                        selectedEntry = nil // Dismiss detail view when tapping outside
                    }
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Check-in Details")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if !entry.mood.isEmpty {
                            Text("Moods:")
                                .foregroundStyle(.primary)
                                .font(.headline)
                            Text(entry.mood.split(separator: ",").map { moodEmojiMap[String($0)] ?? String($0) }.joined(separator: ", "))
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !entry.moodReason.isEmpty {
                            Text("Reason:")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(entry.moodReason)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !entry.nextAction.isEmpty {
                            Text("Next Action:")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(entry.nextAction)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Alertness:")
                                .bold()
                                .foregroundStyle(.primary)
                            Text("\(entry.alertness)")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Calmness:")
                                .bold()
                                .foregroundStyle(.primary)
                            Text("\(entry.calmness)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                    
                    Button {
                        selectedEntry = nil
                    } label: {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)
                }
                .background(
                    Group {
                        if colorScheme == .light {
                            Color.white
                        } else {
                            Color(.systemGray5)
                        }
                    })
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(20)
            }
            
        }
        .onAppear {
            if let userId = userManager.currentUser?.id {
                checkInManager.fetchCheckInEntries(userId: userId)
            }
        }
    }
}
