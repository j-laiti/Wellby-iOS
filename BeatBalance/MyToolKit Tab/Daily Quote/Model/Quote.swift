//
//  Quote.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/31/24.
//

import Foundation

struct Quote: Codable, Identifiable {
    let id: Int
    let quote: String
    let author: String
}
