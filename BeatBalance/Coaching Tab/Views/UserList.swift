//
//  UserList.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/10/24.
//

import SwiftUI

struct UserList: View {
    @EnvironmentObject var userManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    @ObservedObject var chatManager: ChatManager
    let selectedNewUser: (User) -> ()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Button {
                    messageAll()
                } label: {
                    Label("Message all students", systemImage: "megaphone")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(settings.primaryColor)
                        .cornerRadius(8)
                }
                
                ForEach(userManager.userList) { user in
                    Button {
                        selectedUser(user)
                    } label: {
                        HStack(spacing: 40) {
                            
                            Text(user.username)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right.circle")
                            
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 40)
                }
            }
            .padding()
        }
    }
    
    private func messageAll() {
        dismiss()
        chatManager.enterMessageAllSwap()
    }
    
    private func selectedUser(_ user: User) {
        selectedNewUser(user)
        userManager.chatUser = user
        dismiss()
        chatManager.enterChatSwap()
    }
}
