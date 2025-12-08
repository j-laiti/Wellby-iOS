//
//  HRVCheckInView.swift
//  BLEStreaming
//
//  Created by Justin Laiti on 4/12/24.
//

import SwiftUI

struct PostRecordingView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var hrvDataManager = HRVDataManager.shared
    @EnvironmentObject var userManager: AuthManager
    
    @StateObject var checkInManager = CheckInManager()
    @Environment(\.colorScheme) var colorScheme
    
    @State private var mood: String = ""
    @State private var alertSelected: Int = 0
    @State private var calmSelected: Int = 0
    @State private var customReason: String = ""
    @State private var customAction: String = ""
    
    var isFormComplete: Bool {
        calmSelected != 0
    }
    
    @State private var navigateBack = false
    
    var body: some View {
        
        VStack (alignment: .leading) {
            
            // handle if there are more than 4 then show optional check-ins
//            if hrvDataManager.calibrationRecordCount > 3 {
//                HStack {
//                    Spacer()
//                    Button {
//                        navigateBack = true
//                    } label: {
//                        Image(systemName: "x.circle")
//                    }
//                }
//                Text("Optional Check-in")
//            }
            
            ExtendedCheckIn(
                checkInManager: checkInManager,
                mood: $mood,
                relaxedSlider: Binding(get: { Double(calmSelected) }, set: { calmSelected = Int($0) }),
                alertSlider: Binding(get: { Double(alertSelected) }, set: { alertSelected = Int($0) }),
                customReason: $customReason,
                customAction: $customAction,
                showExtendedCheckIn: $navigateBack,
                linkedToRecording: true
            )
        }
        .navigationBarBackButtonHidden()
        .navigationDestination(isPresented: $navigateBack) {
            BiofeedbackScreen()
        }
        .onAppear {
            
            // First, flush any remaining buffered data
            HRVDataManager.shared.flushRawDataBuffer(sessionID: bluetoothManager.sessionID.uuidString)

            // Wait for data to sync before processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if let userID = userManager.userSession?.uid {
                    print("Starting remote processing for session: \(bluetoothManager.sessionID.uuidString)")
                    hrvDataManager.remotePpgProcessing(participantID: userID, hrvDocumentID: bluetoothManager.sessionID.uuidString) { data in
                        if let data = data {
                            print("Received PPG data: \(data)")
                        } else {
                            print("Failed to fetch PPG data")
                        }
                    }
                }
            }
            
            // upload "isCalibrated" bool to firebase
            if let userID = userManager.userSession?.uid {
                hrvDataManager.uploadCalibrationData(userID: userID, recordingID: bluetoothManager.sessionID.uuidString)
            }
        }
    }
    
}

