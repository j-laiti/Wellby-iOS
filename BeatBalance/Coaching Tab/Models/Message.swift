//
//  Message.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/10/24.
//

import Foundation
import Firebase

struct Message: Identifiable, Codable {
    var id: String
    var currentUserID: String
    var receiverID: String
    var text: String
    var timestamp: Date
}
