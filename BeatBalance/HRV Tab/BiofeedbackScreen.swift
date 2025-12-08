//
//  ContentView.swift
//  BLEStreaming
//
//  Created by Justin Laiti on 3/30/24.
//

import SwiftUI

struct BiofeedbackScreen: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @StateObject var hrvDataManager = HRVDataManager.shared
    @EnvironmentObject var userManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingHRVInfoAlert = false
    @State private var hasFetchedData = false
    
    
    struct Metric {
            let name: String
            let icon: String
            let value: String
        }
    
    private var metrics: [Metric] {
        guard let data = hrvDataManager.latestHRVData else {
            return [
                Metric(name: "Calming Response", icon: "leaf.fill", value: "--"),
                Metric(name: "Return to Balance", icon: "figure.yoga", value: "--"),
                Metric(name: "Heart Rate", icon: "heart.fill", value: "--"),
                Metric(name: "Recording Quality", icon: "waveform.path.ecg", value: "--")
            ]
        }
        // Rounding the values for display
        let displaySdnn = String(format: "%d", Int(round(Float(data.sdnn) ?? 0)))
        let displayRmssd = String(format: "%d", Int(round(Float(data.rmssd) ?? 0)))
        let displayAverageHR = String(format: "%d", Int(round(Float(data.averageHR) ?? 0)))
        
        return [
            Metric(name: "Calming Response", icon: "leaf.fill", value: "\(displayRmssd) ms"),
            Metric(name: "Return to Balance", icon: "figure.yoga", value: "\(displaySdnn) ms"),
            Metric(name: "Heart Rate", icon: "heart.fill", value: "\(displayAverageHR) bpm"),
            Metric(name: "Recording Quality", icon: "waveform.path.ecg", value: data.signalQuality)
        ]
    }

    var body: some View {
        
        NavigationStack {
            ScrollView {
                
                VStack(spacing: 20 ) {
                    if hrvDataManager.isProcessingData {
                        ProgressView("Processing data...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        
                        VStack(spacing: 30) {
                            
                            HRVDashboardTitle
                            
                            VStack {
                                
                                HRVTitleBar
                                
                                HRVMetricGrid
                                
                                HRVButtonOptions
                                
//                                RelaxationScale()
                                
                            }
                            .padding(10)
                            .padding(.vertical, 10)
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
                            .padding(.horizontal)
                            
                            bottomButtonOptions
                            
                        }
                    }
                }
                .navigationBarBackButtonHidden()
                .onAppear {
                    // Only fetch once
                    if !hasFetchedData {
                        hasFetchedData = true
                        if let userID = userManager.userSession?.uid {
                            hrvDataManager.fetchLatestHRVData(userID: userID)
                        }
                    }
                }
            }
            .background(
                Group {
                    if colorScheme == .light {
                        LinearGradient(gradient: Gradient(colors: [settings.secondaryColor.opacity(0.7), .white]), startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea()
                    } else {
                        Color.clear
                            .ignoresSafeArea()
                    }
                }
            )
        }
    }
    
    var HRVDashboardTitle: some View {
        VStack {
            HStack {
                Spacer()
                if bluetoothManager.isConnected {
                    BatteryStatus
                }
                BLEConnectButton(bluetoothManager: bluetoothManager)
            }
            .padding(.horizontal)
            
            HStack {
                Text("Wearable Dashboard")
                    .bold()
                    .font(.title)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    var BatteryStatus: some View {
        Group {
            if bluetoothManager.batteryStatus == "R" {
                Image(systemName: "battery.25")
                    .foregroundColor(.red)
            } else if bluetoothManager.batteryStatus == "Y" {
                Image(systemName: "battery.50")
                    .foregroundColor(.yellow)
            } else if bluetoothManager.batteryStatus == "G" {
                Image(systemName: "battery.100")
                    .foregroundColor(.green)
            } else {
            }
        }
    }
    
    var HRVTitleBar: some View {
        HStack {
            
            Text("Recent Measures:")
                .font(.title3)
                .foregroundStyle(.primary)
            
            Spacer()
            
            HRVMetricsInfoButton
            
        }
        .padding(.horizontal)
    }
    
    var HRVMetricsInfoButton: some View {
        Button {
            showingHRVInfoAlert = true
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
        }
        .alert("HRV Metrics", isPresented: $showingHRVInfoAlert) {
            Button("OK", role: .cancel) { }
        }
        message: {
            Text("'Calming Response' shows relaxation levels while 'Return to Balance' indicates the balance between activity and relaxation in your body. Higher values for each suggest more relaxation/balance. HRV can be confusing, so check out the HRV Info section for more clarity!")
        }
    }
    
    var HRVMetricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(metrics, id: \.name) { metric in
                VStack {
                    Image(systemName: metric.icon)
                        .font(.title)
                    Text(metric.value)
                        .font(.body)
                    Text(metric.name)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(5)
            }
        }
    }
    
    var HRVButtonOptions: some View {
        VStack(spacing: 0) {
            NavigationLink {
                StartRecordingView(bluetoothManager: bluetoothManager, hrvDataManager: hrvDataManager)
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Start a new recording")
                        .font(.body)
                }
                .padding(10)
                .padding(.horizontal)
            }
            .disabled(!bluetoothManager.isConnected)
            
            Divider()
                .foregroundStyle(.white)
                .frame(width:250)

            NavigationLink {
                HRVSummaryView(hrvDataManager: hrvDataManager)
            } label: {
                HStack {
                    Image(systemName: "list.bullet.rectangle.portrait")
                    Text("View session summary")
                        .font(.body)
                }
                .padding(10)
                .padding(.horizontal)
            }
            .background(.clear)
            .foregroundColor(.primary)
        }
        .buttonStyle(.plain) // Add this to remove default button padding and allow full width
        .background(.secondary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.top) // Add padding at the top if needed
    }
    
    var bottomButtonOptions: some View {
        HStack {
            Spacer()
            
            NavigationLink {
                BreathPacer()
            } label: {
                VStack {
                    Image(systemName: "wind")
                        .font(.title)
                        .padding(.bottom, 10)
                    Text("Breath")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                    Text("Pacer")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                }
                .padding(15)
                .padding(.horizontal, 15)
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
            }
            
            Spacer()
            
            NavigationLink {
                HRVInfoScreen()
            } label: {
                VStack {
                    Image(systemName: "info.bubble")
                        .font(.title)
                        .padding(.bottom, 10)
                    Text("HRV")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                    Text("Information")
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                }
                .padding(15)
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
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
