//
//  RecordingView.swift
//  BLEStreaming
//
//  Created by Justin Laiti on 4/11/24.
//

import SwiftUI
import Combine

struct RecordingView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @ObservedObject var hrvDataManager = HRVDataManager.shared
    
    var recordingType: RecordingType
    
    // Timer properties
    @State private var progress = 0.0
    @State private var timerSubscription: Cancellable? = nil
    
    // Animation properties for breath pacer
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    @State private var breathInTime: Double = 5.0
    @State private var breathOutTime: Double = 5.0
    @State private var breathStatus: String = "Breathe In"
    
    @State private var navigateToNextScreen = false

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    // Stop recording here
                    bluetoothManager.stopPPGRecording()
                    timerSubscription?.cancel()
                    navigateToNextScreen = true
                }) {
                    Image(systemName: "xmark")
                        .font(.title)
                        .padding()
                        .foregroundColor(.gray)
                }
            }
            
            // Switch between different recording types
            if recordingType == .timerOnly {
                heartBeatAnimation
            } else if recordingType == .breathPacer {
                resonantBreathPacer
            }
            
            if recordingType == .rawData || recordingType == .breathAndRawData {
                PPGWaveformView(ppgReadings: bluetoothManager.rawPPGReadings)
                    .frame(height: 200)
                    .padding()
            }
            
            Text("Recording heart activity...")
                .font(.headline)
            
            ProgressView(value: min(progress, 60), total: 60)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 20)
                .padding(.horizontal, 60)
            
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timerSubscription?.cancel()
        }
        .navigationDestination(isPresented: $navigateToNextScreen) {
            PostRecordingView(bluetoothManager: bluetoothManager)
        }
        .navigationBarBackButtonHidden()
    }
    
    private func startTimer() {
        timerSubscription = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                DispatchQueue.main.async {
                    if self.progress < 60 {
                        self.progress += 0.01
                    } else {
                        self.isAnimating = false
                        self.bluetoothManager.stopPPGRecording()
                        self.timerSubscription?.cancel()
                        self.navigateToNextScreen = true
                    }
                }
            }
    }
    
    var heartBeatAnimation: some View {
        Image(systemName: "heart.fill")
            .font(.title)
            .foregroundColor(.red.opacity(0.75))
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            .padding()
    }
    
    var resonantBreathPacer: some View {
        VStack {
            Text(breathStatus)
                .font(.title)
                .fontWeight(.medium)
                .transition(.opacity.combined(with: .slide))
                .animation(.easeInOut, value: breathStatus)
                .padding()
            
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [.white, .blue.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 75, height: 75)
                .scaleEffect(scale)
                .frame(width: 200, height: 250)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        breathStatus = "Breathe In"
        withAnimation(.easeInOut(duration: breathInTime)) {
            scale = 3.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + breathInTime) {
            self.breathStatus = "Breathe Out"
            withAnimation(.easeInOut(duration: self.breathOutTime)) {
                self.scale = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + self.breathOutTime) {
                self.startAnimationSequence()  // Recursively start the sequence
            }
        }
    }
}

struct PPGWaveformView: View {
    var ppgReadings: [Double]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !ppgReadings.isEmpty else { return }
                
                let width = geometry.size.width
                let height = geometry.size.height
                let maxReading = (ppgReadings.max() ?? 1.0)
                let minReading = (ppgReadings.min() ?? 0.0)
                
                // Scale the data to fit within the view's height
                let scaledReadings = ppgReadings.map { ($0 - minReading) / (maxReading - minReading) * height }
                
                path.move(to: CGPoint(x: 0, y: height - scaledReadings[0]))
                for i in 1..<scaledReadings.count {
                    let x = width * CGFloat(i) / CGFloat(scaledReadings.count)
                    let y = height - scaledReadings[i]
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(Color.red, lineWidth: 2)
        }
    }
}
