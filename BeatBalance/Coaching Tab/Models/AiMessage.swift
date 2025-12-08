//
//  AiMessage.swift
//  BeatBalance
//
//  Created by Justin Laiti on 11/17/24.
//

import Foundation

struct AiMessage: Identifiable, Codable, Equatable {
    var id: String
    var text: String
    var received: Bool
}

extension AiMessage {
    init(chatGPTMessage: ChatGPTMessage) {
        self.id = UUID().uuidString
        self.text = chatGPTMessage.content.first?.text.value ?? ""
        self.received = chatGPTMessage.role == "assistant"
    }
}
