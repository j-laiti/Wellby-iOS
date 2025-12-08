//
//  ChatManager.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/10/24.
//

import Foundation
import Firebase
import FirebaseFirestore

@MainActor
class ChatManager: ObservableObject {
    @Published var message = ""
    @Published var messages: [Message] = []
    @Published var recentMessages: [RecentMessage] = []
    @Published var enterChat = false
    @Published var enterMessageAll = false
    var userManager: AuthManager
    @Published var lastMessageID = ""
    var currentUserID: String {
        userManager.currentUser?.id ?? ""
    }
    var receiverID: String {
        userManager.chatUser?.id ?? ""
    }
    var currentUserName: String {
        userManager.currentUser?.username ?? ""
    }
    var recieverUsername: String {
        userManager.chatUser?.username ?? ""
    }
    
    init(userManager: AuthManager) {
        self.userManager = userManager
        fetchRecentMessages()
        print("initialised")
    }
    
    let db = Firestore.firestore()
    
    func sendMessage() {
        print(message)
         
        //save for sender
        //1. define path
        let document = db.collection("messages")
            .document(currentUserID)
            .collection(receiverID)
            .document()
        
        //2. define data
        let newMessage = ["id": "\(UUID())", "currentUserID": currentUserID, "receiverID": receiverID, "text": message, "timestamp": Date()] as [String: Any]
        //3.store data in path!
        document.setData(newMessage) { error in
            if let error = error {
                print("failed to save message in Firestore: \(error)")
            }
        }
        
        //save for recipient
        let recievedDocument = db.collection("messages")
            .document(receiverID)
            .collection(currentUserID)
            .document()
    
        recievedDocument.setData(newMessage) { error in
            if let error = error {
                print("failed to save message in Firestore: \(error)")
            }
        }
        //save the most recent message in Firestore
        saveLastMessage()
    }
    
    func getMessages() {
        guard !currentUserID.isEmpty, !receiverID.isEmpty else {
                print("CurrentUserID or RecieverID is empty. Cannot fetch messages.")
                return
            }

        db.collection("messages")
            .document(currentUserID)
            .collection(receiverID)
            .order(by: "timestamp", descending: false)
            .limit(toLast: 25)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("error fetching document: \(String(describing: error))")
                    return
                }
                
                self.messages = documents.compactMap { document -> Message? in
                    do {
                        print("trying to load a Message")
                        return try document.data(as: Message.self)
                    } catch {
                        print("error decoding document: \(error)")
                        return nil
                    }
                }
                
                //order messages by time
                self.messages.sort {$0.timestamp < $1.timestamp}
                
                //keep track of the most recent message
                if let id = self.messages.last?.id {
                    self.lastMessageID = id
                }
            }
    
    }
    
    private func saveLastMessage() {
        let document = db.collection("recent_messages")
            .document(currentUserID)
            .collection("messages")
            .document(receiverID)
        
        let lastMessage = [
            "timestamp": Timestamp(),
            "message": message,
            "currentID": currentUserID,
            "chatUserID": receiverID,
            "name": recieverUsername,
            "viewed": true
            // Add the viewed variable here //
        ] as [String : Any]
        
        document.setData(lastMessage) { error in
            if let error = error {
                print("Failed to save recent message \(error)")
                return
            }
        }
        
        //save for the recipient
        let document2 = db.collection("recent_messages")
            .document(receiverID)
            .collection("messages")
            .document(currentUserID)
        //need to change this eventually
        let lastMessage2 = [
            "timestamp": Timestamp(),
            "message": message,
            "chatUserID": currentUserID,
            "currentID": receiverID,
            "name": currentUserName,
            "viewed": false
        ] as [String : Any]
        
        document2.setData(lastMessage2) { error in
            if let error = error {
                print("Failed to save recent message \(error)")
                return
            }
        }
    }
    
    func fetchRecentMessages() {
        guard !currentUserID.isEmpty else {
                print("CurrentUserID is empty. Cannot fetch recent messages.")
                return
            }
        
        db.collection("recent_messages")
            .document(currentUserID)
            .collection("messages")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("error fetching recent messages: \(String(describing: error))")
                    return
                }
                
                self.recentMessages = documents.compactMap { document -> RecentMessage? in
                    do {
                        print("trying to load recent messages")
                        return try document.data(as: RecentMessage.self)
                    } catch {
                        print("error decoding document: \(error)")
                        return nil
                    }
                }
                
                //order messages by time
                self.recentMessages.sort {$1.timestamp < $0.timestamp}
            }
    }
    
    func enterChatSwap() {
        enterChat.toggle()
    }
    
    func enterMessageAllSwap() {
        enterMessageAll.toggle()
    }
    
    func viewStatusTrue() {
        // navigate to the current users recent message
        let document = db.collection("recent_messages")
            .document(currentUserID)
            .collection("messages")
            .document(receiverID)
        
        // set the recent message 'viewed' to true
        document.updateData(["viewed": true]) { error in
            if let error = error {
                print("Failed to save recent message \(error)")
                return
            }
        }
    }
    
    func messageAllStudents() {
        
        for user in userManager.userList {
            userManager.chatUser = user
            sendMessage()
        }
    }
    
    
    // function to mark objectionable content
    func reportObjectionableContent() {
        guard !currentUserID.isEmpty, !receiverID.isEmpty else {
            print("CurrentUserID or ReceiverID is empty. Cannot report content.")
            return
        }

        // Define data for the report
        let reportData = [
            "reporterID": currentUserID,
            "reportedUserID": receiverID,
            "timestamp": Timestamp(),
            "resolved": false
        ] as [String: Any]

        // Add the report to the objectionable content collection
        let document = db.collection("objectionable_content").document()
        document.setData(reportData) { error in
            if let error = error {
                print("Failed to report objectionable content: \(error)")
            } else {
                print("Objectionable content reported successfully")
            }
        }
    }
    
    // funtion to block the user and remove them from the user list/disable the message feature
    func blockChatUser() {
        guard !currentUserID.isEmpty, !receiverID.isEmpty else {
            print("CurrentUserID or ReceiverID is empty. Cannot block user.")
            return
        }

        // Identify who is the student and who is the coach
        let studentID = userManager.currentUser?.student == true ? currentUserID : receiverID
        // Update the student's 'assignedCoach' to 0 in Firestore, indicating they are blocked
        let studentDocument = db.collection("users").document(studentID)

        studentDocument.updateData(["assignedCoach": 0]) { error in
            if let error = error {
                print("Error blocking user: \(error.localizedDescription)")
            } else {
                print("User successfully blocked.")
            }
        }
        
    }

}

