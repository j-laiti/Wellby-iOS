import SwiftUI

struct HRVSummaryView: View {
    @ObservedObject var hrvDataManager: HRVDataManager
    @EnvironmentObject var userManager: AuthManager

    var body: some View {
        VStack {
            if hrvDataManager.hrvDataList.isEmpty {
                VStack {
                    Text("Fetching HRV data...")
                    ProgressView()
                        .onAppear {
                            if let userID = userManager.userSession?.uid {
                                hrvDataManager.fetchHRVData(userID: userID, limit: 5)
                            }
                        }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(hrvDataManager.hrvDataList, id: \.id) { hrvData in
                            SummaryCard(hrvData: hrvData)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .navigationTitle("HRV Summary")
        .onAppear {
            userManager.viewDidAppear(screen: "HRV Summary")
        }
    }
}

struct SummaryCard: View {
    let hrvData: HRVSessionData
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Date: \(hrvData.timestamp?.formatted(date: .numeric, time: .omitted) ?? "Unknown")")
                .font(.headline)
                .padding(.bottom, 5)

            HStack(spacing: 20) {
                MetricView(title: "Heart Rate", value: hrvData.averageHR)
                MetricView(title: "Signal Quality", value: hrvData.signalQuality)
            }

            HStack(spacing: 20) {
                MetricView(title: "Return to Balance", value: hrvData.sdnn)
                MetricView(title: "Calming Response", value: hrvData.rmssd)
            }
        }
        .padding()
        .background(colorScheme == .light ? Color.white : Color.gray.opacity(0.1)) // Adaptive background
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

struct MetricView: View {
    var title: String
    var value: String
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? "--" : value)
                .font(.title3)
                .bold()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .light ? Color.white : Color.gray.opacity(0.2)) // Adaptive background
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
