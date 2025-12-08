//
//  HRVSessionData.swift
//  BeatBalance
//
//  Created by Justin Laiti on 4/14/24.
//

import Foundation
import FirebaseFirestore

struct HRVSessionData: Codable, Identifiable, Hashable {
    var id: String // Firestore document ID
    var sdnn: String
    var rmssd: String
    var averageHR: String
    var signalQuality: String
    var stress_probability: Double
    var timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case sdnn = "sdnn"
        case rmssd = "rmssd"
        case averageHR = "HR_mean"
        case signalQuality = "sqi"
        case stress_probability
        case timestamp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? ""

        // Decode and round numbers to 2 decimal places
        if let sdnnValue = try? container.decode(Double.self, forKey: .sdnn) {
            self.sdnn = String(format: "%.1f", sdnnValue)
        } else if let sdnnValue = try? container.decode(String.self, forKey: .sdnn) {
            self.sdnn = sdnnValue
        } else {
            self.sdnn = ""
        }

        if let rmssdValue = try? container.decode(Double.self, forKey: .rmssd) {
            self.rmssd = String(format: "%.1f", rmssdValue)
        } else if let rmssdValue = try? container.decode(String.self, forKey: .rmssd) {
            self.rmssd = rmssdValue
        } else {
            self.rmssd = ""
        }

        if let averageHRValue = try? container.decode(Double.self, forKey: .averageHR) {
            self.averageHR = String(format: "%.1f", averageHRValue)
        } else if let averageHRValue = try? container.decode(String.self, forKey: .averageHR) {
            self.averageHR = averageHRValue
        } else {
            self.averageHR = ""
        }

        if let signalQuality = try? container.decode(Double.self, forKey: .signalQuality) {
            if signalQuality < 0.3 {
                self.signalQuality = "Low"
            } else if signalQuality >= 0.3 && signalQuality < 0.7  {
                self.signalQuality = "Good"
            } else {
                self.signalQuality = "Excellent"
            }
        } else if let signalQuality = try? container.decode(String.self, forKey: .signalQuality) {
            self.signalQuality = signalQuality
        } else {
            self.signalQuality = "--"
        }
        
        // Decode stress probability
        self.stress_probability = try container.decodeIfPresent(Double.self, forKey: .stress_probability) ?? 0.5

        // Convert Firestore Timestamp to Date
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sdnn, forKey: .sdnn)
        try container.encode(rmssd, forKey: .rmssd)
        try container.encode(averageHR, forKey: .averageHR)
        try container.encode(signalQuality, forKey: .signalQuality)
        try container.encode(stress_probability, forKey: .stress_probability)
        if let timestamp = timestamp {
            try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        }
    }
}

