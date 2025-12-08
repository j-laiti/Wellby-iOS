//
//  MessageList.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/10/24.
//

import SwiftUI

struct ChatTabEntry: View {
    @EnvironmentObject var userManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var aiMessagesManager: AiMessagesManager // EnvironmentObject for AiMessagesManager
    @StateObject var chatManager: ChatManager
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isEditing = false
    @State private var statusText: String = ""
    
    @State private var showOptInConfirmationDialog = false
    @State private var newOptInValue: Bool = false
    
    @State var userListPresented = false
        
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                // TODO: can I wait to load this until a currentUser is fetched? Students are getting a blank screen here - probably if no signal?? also check how the user info is saved and if its possible for this to load even if there is no connection
                
                messageHeader
                
                Spacer() // TODO: see if this affects the coaching view
                                
                if let currentUser = userManager.currentUser {
                    
                    if currentUser.student {
                        
                        if currentUser.isCoachingOptedIn ?? false {
                            Spacer()
                            listCoach
                            Spacer()
                            coachInfoButton
                            Spacer()
                            Divider()
                                .padding(.horizontal)
                                .foregroundStyle(Color.primary)
                            Spacer()
                        }

                        wellbyAutomatedChat
                        Spacer()
                        HStack {
                            Spacer()
                            furtherResourcesButton
                            Spacer()
                            wellbyAiInfo
                            Spacer()
                        }
                        Spacer()
                        
                        if !(currentUser.isCoachingOptedIn ?? false) {
                            coachingSettingsLink
                            Spacer()
                        }

                        
                    } else {
                        
                        messageList
                        newMessage
                        
                    }
                }
                
            }
            .navigationDestination(isPresented: $chatManager.enterChat) {
                Chat(chatManager: chatManager)
                    .onDisappear {
                        userManager.clearChatUser()
                    }
            }
            .navigationDestination(isPresented: $chatManager.enterMessageAll) {
                MessageAll(chatManager: chatManager)
                    .environmentObject(userManager)
            }
            .navigationBarBackButtonHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Group {
                    if colorScheme == .light {
                        LinearGradient(gradient: Gradient(colors: [settings.secondaryColor.opacity(0.7), .white]), startPoint: .top, endPoint: .bottom)
                            .ignoresSafeArea()
                    } else {
                        Color.clear
                            .ignoresSafeArea()
                    }
                }
            )
        }
        .onAppear {
            userManager.viewDidAppear(screen: "Coaching Chat")
        }
    }
    
    var messageHeader: some View {
        
        HStack {
            
            if let currentUser = userManager.currentUser {
                if !currentUser.student {
                    VStack(alignment: .leading) {
                        Text("Hi \(userManager.currentUser?.username ?? "")")
                            .bold()
                            .font(.title2)
                        HStack {
                            if isEditing {
                                TextField("Enter new status", text: $statusText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            } else {
                                Text("Current status: \(currentUser.status)")
                                    .foregroundStyle(.gray)
                            }
                            
                            Button {
                                if isEditing {
                                    userManager.updateCoachStatus(to: statusText)
                                }
                                isEditing.toggle()
                            } label: {
                                Image(systemName: isEditing ? "checkmark.circle" : "pencil")
                            }
                        }
                    }
                } else {
                    Text("Start a chat:")
                        .bold()
                        .font(.title)
                        .foregroundStyle(.primary)
                }
            } else {
                Text("No connection - Could not fetch chat data")
                    .bold()
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
                
            Spacer()
            
            
        }
        .padding()
        
    }
    
    var messageList: some View {
        ScrollView {

            ForEach(chatManager.recentMessages) {message in
                Button {
                    let currentUserID = userManager.currentUser?.id ?? ""
                    
                    if currentUserID == message.currentID {
                        userManager.getUserByID(id: message.chatUserID) { user in
                            userManager.chatUser = user
                            chatManager.enterChatSwap()
                      }
                  } else if currentUserID == message.chatUserID {
                      userManager.getUserByID(id: message.currentID) { user in
                          // This is the counterpart user in the message, so set this user as the chat user
                          userManager.chatUser = user
                          chatManager.enterChatSwap()
                      }
                  }
                  
                  if !message.viewed {
                      // Update the message view status if necessary
                      chatManager.viewStatusTrue()
                  }
                    
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(message.viewed ? Color.clear : Color.blue)
                            .frame(width: 10, height: 10)
                        
                        VStack(alignment: .leading) {
                            Text(message.name)
                                .font(.headline)
                            
                            Text(message.message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                        .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        Text(message.timeAgo)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.trailing)
                        
                    }.padding(.horizontal)

                }
                .foregroundColor(.primary)
                .padding(.vertical, 5)
                
                Divider()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 30)

            }
        }
        .padding(10)
        .background(
            Group {
                if colorScheme == .light {
                    Color.white
                } else {
                    Color.gray.opacity(0.3)
                }
            })
        .cornerRadius(25)
        .shadow(radius: 5)
        .padding(.horizontal, 10)
    }
    
    var newMessage: some View {
        Button {
            userListPresented = true
        } label: {
            Label("New Message", systemImage: "plus.circle")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(settings.primaryColor)
                .cornerRadius(8)
        }
        .padding(.bottom)
        .sheet(isPresented: $userListPresented) {
            UserList(chatManager: chatManager, selectedNewUser: {user in
                print(user.username)
            })
        }
        .onAppear {
            userManager.fetchAssignedStudents()
        }
        .foregroundStyle(settings.primaryColor)
    }
    
    var listCoach: some View {
        VStack(alignment: .leading) {
            if userManager.coachesList.isEmpty {
                // Display this text if no coaches were found
                Text("No coach found")
                    .font(.title3)
                    .padding()
                    .foregroundColor(.gray)
            } else {
                ForEach(userManager.coachesList) { coach in
                    Button {
                        
                        userManager.chatUser = coach
                        chatManager.enterChatSwap()
                        
                        if let viewed = chatManager.recentMessages.first?.viewed {
                            if !viewed {
                                // change the message data to be viewed
                                chatManager.viewStatusTrue()
                            }
                        }
                        
                    } label: {
                        
                        HStack(alignment: .center) {
                            
                            Image("coach")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 90)
                                .padding(10)
                            
                            VStack(alignment: .leading) {
                                Text("Health Coach")
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(.primary)
                                    .padding(.bottom, 10)
                                
                                HStack(alignment: .center) {
                                    Text(coach.username)
                                        .font(.title3)
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(settings.primaryColor)
                                        .padding(.horizontal, 10)
                                }
                                
                                if coach.status != "" {
                                    Text("Coach's status: \(coach.status)")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                        .lineLimit(3)
                                }
                                
                                HStack {
                                    if let viewed = chatManager.recentMessages.first?.viewed {
                                        if !viewed {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                    
                                        if let lastMessage = chatManager.recentMessages.first {
                                            Text("Recent message: \(lastMessage.message)")
                                                .font(.subheadline)
                                                .lineLimit(3)
                                                .foregroundStyle(.secondary)

                                            Text(lastMessage.timeAgo)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                }
                            }
                            .multilineTextAlignment(.leading)
                            
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .foregroundStyle(.primary)
                    
                }
            }
        
        }
        .padding(15)
        .background(
            Group {
                if colorScheme == .light {
                    Color.white
                } else {
                    Color.gray.opacity(0.3)
                }
            })
        .cornerRadius(25)
        .shadow(radius: 5)
        .padding(.horizontal, 30)
        .onAppear {
            userManager.fetchAssignedCoach()
        }
    }
    
    var coachInfoButton: some View {
        NavigationStack {
            NavigationLink {
                CoachingInfo()
            } label: {
                HStack {
                    Image(systemName: "note.text")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20, alignment: .leading)
                        .foregroundColor(settings.primaryColor)
                    
                    Text("Coaching Info")
                        .bold()
                        .foregroundStyle(Color.primary)
                }
                .padding()
                .background(
                    Group {
                        if colorScheme == .light {
                            Color.white
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    })
                .cornerRadius(10)
                .shadow(radius: 5)
            }
        }
    }
    
    var coachingSettingsLink: some View {
        NavigationLink(destination: Settings()) {
            HStack {
                Text(
                    userManager.currentUser?.isCoachingOptedIn ?? false ?
                    "Opt-out of coaching in settings" :
                        "Opt-in to coaching in settings"
                )
                .foregroundStyle(Color.primary)
                .font(.subheadline)
                .padding(10)
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(settings.primaryColor)
            }
            .padding(10)
            .background(
                Group {
                    if colorScheme == .light {
                        Color.white
                    } else {
                        Color.gray.opacity(0.3)
                    }
                })
            .cornerRadius(15)
            .shadow(radius: 5)
        }
    }
    
    var wellbyAutomatedChat: some View {
        NavigationLink {
            ConversationView()
                .environmentObject(aiMessagesManager)
        } label: {
            HStack {
                Image("chatIcon")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                VStack(alignment: .leading) {
                    Text("Wellby AI")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(colorScheme == .light ? .black : .white)
                    Text("Ask questions related to your wellbeing goals to get automatic feedback")
                        .padding(.vertical, 8)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.leading)
                }
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(
                Group {
                    if colorScheme == .light {
                        Color.white
                    } else {
                        Color.gray.opacity(0.3)
                    }
                })
            .cornerRadius(25)
            .shadow(radius: 5)
            .padding(.horizontal, 30)
        }
    }
    
    var furtherResourcesButton: some View {
        NavigationLink(destination: FurtherResourcesView()) {
            VStack {
                Image(systemName: "arrow.up.forward.bottomleading.rectangle")
                    .font(.title)
                    .padding(.bottom, 10)
                
                Text("Further")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                Text("Supports")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
            }
            .padding(15)
            .padding(.horizontal, 15)
            .background(
                Group {
                    if colorScheme == .light {
                        Color.white
                    } else {
                        Color.gray.opacity(0.3)
                    }
                })
            .cornerRadius(25)
            .shadow(radius: 5)
        }
    }
    
    var wellbyAiInfo: some View {
        NavigationLink(destination: AiChatInfo()) {
            VStack {
                Image(systemName: "info.bubble")
                    .font(.title)
                    .padding(.bottom, 10)
                
                Text("Wellby AI")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
                Text("Info")
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primary)
            }
            .padding(15)
            .padding(.horizontal, 15)
            .background(
                Group {
                    if colorScheme == .light {
                        Color.white
                    } else {
                        Color.gray.opacity(0.3)
                    }
                })
            .cornerRadius(25)
            .shadow(radius: 5)
        }
    }
    
}

