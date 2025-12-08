//
//  User.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import Foundation

struct User: Identifiable, Codable {
    var id: String
    var student: Bool
    var school: String = "none"
    var firstName: String
    var surname: String
    var username: String
    var email: String
    var status: String = ""
    var assignedCoach: Int = 0
    var isCoachingOptedIn: Bool? = false
    
    var coachNumber: Int {
        if student {
            return 0
        }
        
        let firstLetter = firstName.prefix(1).lowercased()
        
        switch firstLetter {
        case "a"..."g":
            return 1
        case "h"..."m":
            return 2
        case "n"..."z":
            return 3
        default:
            return 1
        }
    }
    
}
