//
//  AuthManager.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
// Edited on 29/04/25

import Foundation
import Firebase
@preconcurrency import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

// Make the class conform to Sendable
@MainActor
final class AuthManager: ObservableObject, @unchecked Sendable {
    @Published var userSession: FirebaseAuth.User? //this is the firebase user
    @Published var currentUser: User? //this is the user struct that I've defined
    @Published var loginStatus: String? = nil
    @Published var createAccountStatus: String? = nil
    @Published var codeStatus: String? = nil
    @Published var codeFound: Bool = false
    @Published var resetEmailStatus: String? = nil
    
    var isStudent = false
    var school: String = ""
    
    @Published var presentUserMessages = false
    @Published private(set) var userList = [User]()
    @Published private(set) var coachesList = [User]()
    @Published var chatUser: User? //person that the user is messaging
    
    // Make database a private let, as it's immutable
    private let db = Firestore.firestore()
    
    init() {
        // Listen for authentication state changes
        self.userSession = Auth.auth().currentUser
        self.fetchUserIfNeeded()
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            Task { @MainActor in
                if let user = user {
                    self?.userSession = user
                    // Fetch user details if necessary
                    self?.fetchUserIfNeeded()
                } else {
                    // No user is signed in
                    self?.userSession = nil
                    self?.currentUser = nil
                }
            }
        }
    }

    private func fetchUserIfNeeded() {
        if let user = Auth.auth().currentUser {
            // Fetch user details from Firestore
            self.fetchUser(email: user.email ?? "")
        }
    }
    
    //sign in method
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Update UI state on main actor
            await MainActor.run {
                self.userSession = result.user
                print("successfully signed in")
                self.loginStatus = nil
            }
            
            fetchUser(email: email)
            
            // Subscribe to the topic with userId after successful sign in
            let userId = result.user.uid
            do {
                try await Messaging.messaging().subscribe(toTopic: userId)
                print("Subscribed to topic \(userId) successfully")
            } catch {
                print("Error subscribing to topic: \(error)")
            }
        } catch {
            await MainActor.run {
                self.loginStatus = "Unable to sign in with the entered email and password."
                print("DEBUG: failed to login with error \(error.localizedDescription )")
            }
        }
    }
    
    // method to pull user data based on login
    func fetchUser(email: String) {
        // Capture only what's needed in the closure
        let dbRef = self.db
        
        dbRef.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    if let document = querySnapshot?.documents.first {
                        let user = try? document.data(as: User.self)
                        
                        Task { @MainActor in
                            self.currentUser = user
                            if let currentUser = self.currentUser {
                                print("current user saved \(currentUser) :P")
                            } else {
                                print("current user is nilllll")
                            }
                        }
                    } else {
                        print("User not found")
                        Task { @MainActor in
                            self.currentUser = nil
                        }
                    }
                }
            }
    }
    
    //check study codes
    func checkStudyCode(code: String, completion: @escaping (Bool) -> Void) async throws {
        let codeFields = ["school1", "school2", "school3", "school4", "coach"] // name of the code field in Firebase
        var codeExists = false  // Local variable for asynchronous context

        do {
            for codeField in codeFields {
                let dataSnapshot = try await db.collection("studyCodes")
                    .whereField(codeField, isEqualTo: code)
                    .getDocuments()
                
                if !dataSnapshot.isEmpty {
                    codeExists = true
                    break
                }
            }
            
            let localCodeExists = codeExists
            
            await MainActor.run {
                // Update the main variable after async work is done
                self.codeFound = localCodeExists
                if localCodeExists {
                    self.codeStatus = nil
                    if code.hasSuffix("c") {
                        self.isStudent = false
                    } else if code.hasSuffix("g") {
                        self.isStudent = true
                        self.school = "School 1"
                    } else if code.hasSuffix("w") {
                        self.isStudent = true
                        self.school = "School 2"
                    } else if code.hasSuffix("r") {
                        self.isStudent = true
                        self.school = "School 3"
                    } else if code.hasSuffix("t") {
                        self.isStudent = true
                        self.school = "School 4"
                    }
                    else {
                        self.codeStatus = "Error or codes have changed"
                    }
                } else {
                    self.codeStatus = "Couldn't find the entered code."
                }
            }

            // Send the result to the completion handler
            completion(localCodeExists)
        } catch {
            print("Error accessing study codes: \(error.localizedDescription)")
            completion(false)
        }
    }

    //log data to create an account
    func createAccount(withEmail email: String, password: String, firstName: String, surname: String, username: String) async throws {
        do {
            // authenticate login info in Firebase
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let firstLetter = firstName.prefix(1).lowercased()
            let assignedCoach: Int
            let isStudentCopy = self.isStudent
            let schoolCopy = self.school
            
            if isStudentCopy {
                switch firstLetter {
                case "a"..."g":
                    assignedCoach = 1
                case "h"..."m":
                    assignedCoach = 2
                case "n"..."z":
                    assignedCoach = 3
                default:
                    assignedCoach = 3
                }
            } else {
                assignedCoach = 0  // No coach assigned for non-students
            }
            
            let user = User(id: result.user.uid, student: isStudentCopy, school: schoolCopy, firstName: firstName, surname: surname, username: username, email: email, assignedCoach: assignedCoach)

            let encodedUser = try Firestore.Encoder().encode(user)
            try await db.collection("users").document(user.id).setData(encodedUser)

            await MainActor.run {
                self.userSession = result.user
                self.currentUser = user
                self.createAccountStatus = nil
            }
            
            let userId = result.user.uid
            do {
                try await Messaging.messaging().subscribe(toTopic: userId)
                print("Subscribed to topic \(userId) successfully")
            } catch {
                print("Error subscribing to topic: \(error)")
            }
            
        } catch {
            await MainActor.run {
                self.createAccountStatus = "Unable to create an account. Please double check the entered information."
                print("Debug: Failed to create user with error \(error.localizedDescription)")
            }
        }
    }
    
    //password reset
    func resetPassword(forEmail email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("password reset email sent successfully")
            
            await MainActor.run {
                self.resetEmailStatus = "Password reset email sent"
            }
        } catch {
            print("error sending password reset link \(error.localizedDescription)")
            
            await MainActor.run {
                self.resetEmailStatus = "Error in sending password reset link"
            }
        }
    }
    
    //signout method
    func logout() async throws {
        if let userId = currentUser?.id {
            try await Messaging.messaging().unsubscribe(fromTopic: userId)
        }

        do {
            try Auth.auth().signOut()
            
            await MainActor.run {
                self.chatUser = nil
                self.currentUser = nil
                self.userSession = nil
            }
            
        } catch {
            print("not signed out of Firebast Auth")
        }
    }
    
    // for coaches: get a list of students to message
    func fetchAssignedStudents() {
        print("fetching students")
        guard let coachNumber = currentUser?.coachNumber else { return }
        
        print("coach number: \(coachNumber)")
        
        // Use a separate reference to avoid capturing self
        let dbRef = self.db
        
        dbRef.collection("users")
            .whereField("assignedCoach", isEqualTo: coachNumber)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents: \(error)")
                    return
                } else {
                    var newUserList = [User]()
                    
                    // Iterate through the documents and decode them into User objects
                    for document in querySnapshot!.documents {
                        if let user = try? document.data(as: User.self) {
                            newUserList.append(user)
                            print("user added!! \(user)")
                        }
                    }
                    
                    // Update on main actor
                    Task { @MainActor in
                        // Clear the existing user list
                        self.userList.removeAll()
                        self.userList = newUserList
                        self.objectWillChange.send()
                    }
                }
            }
    }
    
    // for students: get a list of coaches to message
    func fetchAssignedCoach() {
        guard let coach = currentUser?.assignedCoach else { return }
        
        // Use a separate reference to avoid capturing self
        let dbRef = self.db
        
        dbRef.collection("users")
            .whereField("student", isEqualTo: false)
            .whereField("coachNumber", isEqualTo: coach)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting documents: \(error)")
                    return
                } else {
                    var newCoachesList = [User]()
                    
                    // Iterate through the documents and decode them into User objects
                    for document in querySnapshot!.documents {
                        if let user = try? document.data(as: User.self) {
                            newCoachesList.append(user)
                        }
                    }
                    
                    // Update on main actor
                    Task { @MainActor in
                        // Clear the existing coaches list
                        self.coachesList.removeAll()
                        self.coachesList = newCoachesList
                        self.objectWillChange.send()
                    }
                }
            }
    }
    
    func getUserByID(id: String, completion: @escaping (User?) -> Void) {
        if let user = userList.first(where: { $0.id == id }) {
            completion(user)
        } else {
            print("User not found in the userList")
            completion(nil)
        }
    }
    
    func updateCoachStatus(to status: String) {
        guard let userId = currentUser?.id else { return }
        
        // Use a separate reference to avoid capturing self
        let dbRef = self.db
        
        // navigate to the current users in user list
        let document = dbRef.collection("users").document(userId)
        
        // set the recent message 'viewed' to true
        document.updateData(["status": status]) { [weak self] error in
            if let error = error {
                print("Failed to save recent message \(error)")
                return
            }
            
            Task { @MainActor in
                self?.currentUser?.status = status
            }
        }
    }
    
    func clearChatUser() {
        Task { @MainActor in
            self.chatUser = nil
        }
    }
    
    func deleteUserAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user is currently logged in."])
        }

        // Delete user data from Firestore
        let userId = user.uid
        
        do {
            try await db.collection("users").document(userId).delete()

            print("User document successfully removed")

            try await user.delete()
            
            await MainActor.run {
                self.userSession = nil
                self.currentUser = nil
            }
            
            print("User authentication record successfully deleted.")
        } catch {
            print("Error removing user data or authentication record: \(error)")
            throw error
        }
    }
    
    //engagement trackers
    func viewDidAppear(screen: String) {
        guard let currentUserId = currentUser?.id else {
            print("didAppear Error: Current user ID is nil.")
            return
        }
        
        // Use a separate reference to avoid capturing self
        let dbRef = self.db
        
        //define path
        let document = dbRef.collection("users").document(currentUserId).collection("engagement").document()
        
        let screenView: [String: Any] = [
            "screen_viewed": screen,
            "timestamp": FieldValue.serverTimestamp()
        ]

        document.setData(screenView) { error in
            if let error = error {
                print("Firestore write error: \(error.localizedDescription)")
            } else {
                print("Test data successfully saved at path: users/\(currentUserId)/engagement/")
            }
        }
    }

    func clickedOn(feature: String) {
        guard let currentUserId = currentUser?.id else {
            print("clickedOn Error: Current user ID is nil.")
            return
        }
        
        // Use a separate reference to avoid capturing self
        let dbRef = self.db
        
        let document = dbRef.collection("users").document(currentUserId).collection("engagement").document()
        
        document.setData([
            "feature_clicked": feature,
            "timestamp": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Firestore write error: \(error.localizedDescription)")
            } else {
                print("Data successfully saved.")
            }
        }
    }

    func applyOptInChange(_ optIn: Bool) {
        guard let userId = currentUser?.id else {
            print("No current user ID available")
            return
        }
        
        // Determine the assigned coach number based on first name
        var coachAssignment = 0
        
        // Create a local copy to avoid capturing self
        if let firstName = self.currentUser?.firstName {
            if optIn {
                if let firstLetter = firstName.prefix(1).lowercased().first {
                    switch firstLetter {
                    case "a"..."m":
                        coachAssignment = 1
                    case "n"..."z":
                        coachAssignment = 2
                    default:
                        coachAssignment = 1 // Default to 1 if the name is unrecognized
                    }
                }
            }
        }
        
        // Use a separate reference to avoid capturing self
        let dbRef = self.db
        
        // Update the local model
        Task { @MainActor in
            self.currentUser?.isCoachingOptedIn = optIn
            self.currentUser?.assignedCoach = coachAssignment
        }
        
        // update the User data on firebase with the new fields
        let documentRef = dbRef.collection("users").document(userId)
        documentRef.updateData([
            "isCoachingOptedIn": optIn,
            "assignedCoach": coachAssignment
        ]) { error in
            if let error = error {
                print("Error updating opt-in status and coach assignment: \(error)")
            } else {
                print("User opt-in status and coach assignment successfully updated in Firebase.")
            }
        }
    }
}
