//
//  CheckInData.swift
//  BeatBalance
//
//  Created by Justin Laiti on 2/26/24.
//

import Foundation

struct CheckInData: Decodable, Identifiable {
    let id = UUID()
    let mood: String
    let alertness: Int
    let calmness: Int
    let moodReason: String
    let nextAction: String
    let date: Date
    let isLinkedToRecording: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case mood, alertness, calmness, moodReason, nextAction, date, isLinkedToRecording
    }
    
    init(
        mood: String,
        alertness: Int,
        calmness: Int,
        moodReason: String,
        nextAction: String,
        date: Date,
        isLinkedToRecording: Bool? = false
    ) {
        self.mood = mood
        self.alertness = alertness
        self.calmness = calmness
        self.moodReason = moodReason
        self.nextAction = nextAction
        self.date = date
        self.isLinkedToRecording = isLinkedToRecording
    }
}
