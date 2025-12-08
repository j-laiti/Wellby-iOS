//
//  MessageBlock.swift
//  BeatBalance
//
//  Created by Justin Laiti on 11/17/24.
//

import SwiftUI

struct MessageBlock: View {
    @EnvironmentObject var settings: UserSettings
    var message: AiMessage
    
    var body: some View {
        VStack(alignment: message.received ? .leading : .trailing) {
            HStack {
                Text(message.text)
                    .padding()
                    .background(message.received ? Color.gray.opacity(0.3) : settings.primaryColor.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                .frame(maxWidth: 300, alignment: message.received ? .leading : .trailing)

            }
        }
        .frame(maxWidth: .infinity, alignment: message.received ? .leading : .trailing)
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

#Preview {
    MessageBlock(message: AiMessage(id: "123", text: "Hey there", received: false))
}
