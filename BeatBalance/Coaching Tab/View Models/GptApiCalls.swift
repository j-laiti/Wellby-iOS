//
//  APICalls.swift
//  BeatBalance
//
//  Created by Justin Laiti on 11/17/24.
//

import Foundation

struct ChatGPTAssistant: Codable {
    let id: String
    let name: String
}

struct ChatGPTThread: Codable {
    let id: String
}

struct ChatGPTRun: Codable {
    let id: String
    let status: String
}

struct ChatGPTRequest: Codable {
    let role: String
    let content: String
}

struct ChatGPTResponse: Codable {
    let data: [ChatGPTMessage]
}

struct ChatGPTMessage: Codable {
    let role: String
    let content: [ChatGPTContent]
}

struct ChatGPTContent: Codable {
    let type: String
    let text: ChatGPTText
}

struct ChatGPTText: Codable {
    let value: String
    let annotations: [String]
}
