//
//  EmojiButton.swift
//  BeatBalance
//
//  Created by Justin Laiti on 10/27/24.
//

import SwiftUI

struct EmojiButton: View {
    var emoji: String
    var description: String
    @Binding var selectedArray: [String]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .center) {
            Text(emoji)
                .font(.title2)
            Text(description)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .padding(10)
        .background(
            Group {
                if selectedArray.contains(description) {
                    Color.blue.opacity(0.2)
                } else {
                    if colorScheme == .light {
                        Color.white
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
            })
        .cornerRadius(15)
        .shadow(radius: 5)
        .onTapGesture {
            if selectedArray.contains(description) {
                selectedArray.removeAll { $0 == description }
            } else {
                selectedArray.append(description)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(selectedArray.contains(description) ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    EmojiButton(emoji: "😩", description: "move your body", selectedArray: .constant(["upset"]))
}
