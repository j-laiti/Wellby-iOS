//
//  MessageEntryBlock.swift
//  BeatBalance
//
//  Created by Justin Laiti on 11/17/24.
//

import SwiftUI

struct MessageEntryBlock: View {
    @EnvironmentObject var messagesManager: AiMessagesManager
    @EnvironmentObject var userManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    @State private var message = ""
    
    var body: some View {
        HStack {
            CustomTextField(placeholder: Text("Enter your message here"), text: $message)
            
            Button {
                messagesManager.sendMessage(text: message)
                message = ""
                userManager.clickedOn(feature: "send Wellby AI a message")
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(settings.primaryColor)
                    .cornerRadius(30)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(50)
        .padding()
    }
}

struct CustomTextField: View {
    var placeholder: Text
    @Binding var text: String
    var editingChanged: (Bool) -> () = {_ in}
    var commit: () -> () = {}
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                placeholder
                    .opacity(0.5)
            }
            
            TextField("", text: $text, onEditingChanged: editingChanged, onCommit: commit)
        }
    }
}
