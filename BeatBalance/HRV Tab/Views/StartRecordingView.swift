//
//  StartRecording.swift
//  BLEStreaming
//
//  Created by Justin Laiti on 4/11/24.
//

import SwiftUI

struct StartRecordingView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var hrvDataManager = HRVDataManager.shared
    @EnvironmentObject var userManager: AuthManager
    
    @State private var selectedRecordingType: RecordingType? = nil
    
    var body: some View {
        VStack {
            RecordingTypeSelection
            
            Button {
                // Generate sessionID first
                let newSessionID = UUID()
                bluetoothManager.sessionID = newSessionID
                
                // Create session document in Firebase
                if let userID = userManager.userSession?.uid {
                    HRVDataManager.shared.createSessionDocument(userID: userID, sessionID: newSessionID.uuidString)
                }
                
                // Then start recording
                bluetoothManager.startPPGRecording()
            } label: {
                Text("Start Recording")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!bluetoothManager.isConnected || selectedRecordingType == nil)
            .padding()
        }
        .navigationDestination(isPresented: $bluetoothManager.beginRecoringViewEnabled) {
            RecordingView(bluetoothManager: bluetoothManager, recordingType: selectedRecordingType ?? .timerOnly)
        }
    }
    
    var RecordingTypeSelection: some View {
        VStack {
            Text("What type of recording would you like to start?")
                .padding(5)
                .font(.headline)
            
            recordingOptionButton(type: .timerOnly, label: "Timer Only", iconName: "timer")
            recordingOptionButton(type: .breathPacer, label: "Breath Pacer", iconName: "wind")
            recordingOptionButton(type: .rawData, label: "Raw Data", iconName: "waveform.path.ecg")
        }
        .frame(maxWidth: 250)
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
    
    @ViewBuilder
    func recordingOptionButton(type: RecordingType, label: String, iconName: String) -> some View {
        HStack {
            Image(systemName: iconName)
                .padding(.horizontal, 5)
                .foregroundColor(selectedRecordingType == type ? .blue : .secondary)
            Text(label)
                .foregroundColor(selectedRecordingType == type ? .primary : .secondary)
        }
        .padding(.vertical, 5)
        .onTapGesture {
            selectedRecordingType = selectedRecordingType == type ? nil : type
        }
    }
}
