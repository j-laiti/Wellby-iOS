//
//  RelaxScale.swift
//  BeatBalance
//
//  Created by Justin Laiti on 11/25/24.
//

import SwiftUI

struct RelaxationScale: View {
    @ObservedObject var hrvDataManager = HRVDataManager.shared
    @EnvironmentObject var userManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        VStack {
            // check the count of the recordings in Firebase on appear
            if hrvDataManager.isLoadingRelaxScale {
                ProgressView()
            } else if let error = hrvDataManager.relaxScaleError {
                VStack {
                    Text(error)
                }
                .padding()
            } else {
                if hrvDataManager.calibrationRecordCount < 4 {
                    Text("Calibration recordings:")
                    
                    HStack(spacing: 10) {
                        ForEach(0..<4) { index in
                            Circle()
                                .strokeBorder(index < hrvDataManager.calibrationRecordCount ? settings.primaryColor : Color.gray, lineWidth: 2)
                                .background(
                                    index < hrvDataManager.calibrationRecordCount
                                    ? Circle().fill(settings.primaryColor) // Filled circle for completed progress
                                    : Circle().fill(Color.clear) // Transparent fill for incomplete
                                )
                                .frame(width: 25, height: 25) // Set fixed size for the dots
                        }
                    }

                } else {
                    
                    Text("Estimated Relaxation")
                        .font(.headline)
                    
                    ZStack {
                        GeometryReader { geometry in
                            let totalWidth = geometry.size.width // Use gradient's actual width
                            
                            // Gradient scale
                            LinearGradient(
                                gradient: Gradient(colors: [.red, .yellow, .green]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(height: 20)
                            .cornerRadius(10)
                            
                            // Dot indicator
                            if let stressProbability = hrvDataManager.latestHRVData?.stress_probability {
                                let relaxProbability = 1 - stressProbability // Swap the scale
                                
                                // Calculate dot position based on the gradient's width
                                let dotPosition = CGFloat(relaxProbability) * totalWidth
                                let clampedPosition = max(0, min(dotPosition, totalWidth)) // Clamp within gradient bounds
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 20, height: 20)
                                    .offset(x: clampedPosition - 10) // Offset by half the dot's width to center it
                                    .shadow(radius: 3)
                            }
                        }
                        .frame(height: 40) // Set a consistent height for the scale
                    }
                    .padding(.horizontal, 40) // Constrain the entire ZStack horizontally
                    
                }
            }
        }
        .padding(.vertical, 10)
        .onAppear {
            DispatchQueue.main.async {
                if let userID = userManager.userSession?.uid {
                    hrvDataManager.checkCalibrationProgress(userID: userID)
                }
            }
        }
    }
}
