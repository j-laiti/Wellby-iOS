//
//  MessageAll.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/24/24.
//

import SwiftUI

struct MessageAll: View {
    @EnvironmentObject var userManager: AuthManager
    @ObservedObject var chatManager: ChatManager
    
    var body: some View {
        VStack {
            Text("Send a message to all students:")
                .bold()
            
            HStack {
                TextEditor(text: $chatManager.message)
                    .font(.system(.body))
                    .frame(height: 100)
                    .cornerRadius(10.0)
                                .shadow(radius: 1.0)
                
                Button {
                    chatManager.messageAllStudents()
                    chatManager.message = ""
                } label: {
                    Image(systemName: "paperplane.circle")
                        .font(.title2)
                }
            }
            .padding(.horizontal)

        }
    }
}
