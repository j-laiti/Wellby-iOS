//
//  RecentMessage.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/10/24.
//

import Foundation
import Firebase

struct RecentMessage: Identifiable, Codable {
    let currentID: String
    let chatUserID: String
    let name: String
    let message: String
    let timestamp: Date
    var viewed: Bool
    
    // to conform to identifiable
    var id: String { chatUserID }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
