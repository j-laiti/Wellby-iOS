//
//  CheckInManager.swift
//  BeatBalance
//
//  Created by Justin Laiti on 2/26/24.
//

import Foundation
import Firebase
import FirebaseFirestore

class CheckInManager: ObservableObject {
    @Published var checkInEntries = [CheckInData]()
    @Published var lastVisibleDocument: DocumentSnapshot?
    @Published var firstVisibleDocument: DocumentSnapshot?
    @Published var canFetchNext: Bool = false
    @Published var canFetchPrevious: Bool = false
    
    let db = Firestore.firestore()
    
    // function to send the entered data to the firestore collection
    func saveCheckinData(checkIn: CheckInData, userId: String) {
        // define path
        let document = db.collection("users").document(userId).collection("checkIns").document()
        // define data
        let checkin: [String: Any] = [
            "mood": checkIn.mood,
            "alertness": checkIn.alertness,
            "calmness": checkIn.calmness,
            "moodReason": checkIn.moodReason,
            "nextAction": checkIn.nextAction,
            "date": Timestamp(date: checkIn.date),
            "isLinkedToRecording": checkIn.isLinkedToRecording ?? false
        ]
        
        document.setData(checkin) { error in
            if let error = error {
                // Handle any errors
                print("Error saving check-in data to Firestore: \(error.localizedDescription)")
            } else {
                print("Successfully saved check-in data to Firestore.")
            }
        }
        
    }
    
    func fetchCheckInEntries(userId: String) {
        
        db.collection("users").document(userId).collection("checkIns")
            .order(by: "date", descending: true)
            .limit(to: 5)
            .getDocuments { (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(String(describing: error))")
                    return
                }
                self.checkInEntries = documents.compactMap { document -> CheckInData? in
                    try? document.data(as: CheckInData.self)
                }.sorted(by: { $0.date < $1.date })
                
                DispatchQueue.main.async {
                    self.lastVisibleDocument = documents.last
                    self.firstVisibleDocument = documents.first
                    self.canFetchNext = false
                    self.updatePreviousNav(userId: userId)
                }
            }
    }
    
    private func updatePreviousNav(userId: String) {
        guard let lastDocument = lastVisibleDocument else { return }
        
        db.collection("users").document(userId).collection("checkIns")
            .order(by: "date", descending: true)
            .start(afterDocument: lastDocument)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                        DispatchQueue.main.async {
                            self.canFetchPrevious = !(snapshot?.isEmpty ?? true)
                        }
                    }
    }
    
    func fetchPreviousEntries(userId: String) {
        guard let lastDocument = lastVisibleDocument else { return }
        
        db.collection("users").document(userId).collection("checkIns")
            .order(by: "date", descending: true)
            .start(afterDocument: lastDocument)
            .limit(to: 5)
            .getDocuments { (querySnapshot, error) in
                guard let newDocuments = querySnapshot?.documents, !newDocuments.isEmpty else {
                    print("Error fetching next documents: \(String(describing: error))")
                    return
                }
                let newEntries = newDocuments.compactMap { document -> CheckInData? in
                    try? document.data(as: CheckInData.self)
                }.sorted(by: { $0.date < $1.date })
                
                
                DispatchQueue.main.async {
                    self.checkInEntries = newEntries
                    self.lastVisibleDocument = newDocuments.last
                    self.firstVisibleDocument = newDocuments.first
                    self.updatePreviousNav(userId: userId)
                    self.canFetchNext = true
                }
            }
    }
    
    private func updateNextNav(userId: String) {
        guard let firstDocument = firstVisibleDocument else { return }
        
        db.collection("users").document(userId).collection("checkIns")
            .order(by: "date", descending: false)
            .start(afterDocument: firstDocument)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                        DispatchQueue.main.async {
                            self.canFetchNext = !(snapshot?.isEmpty ?? true)
                        }
                    }
    }
    
    func fetchNextEntries(userId: String) {
        guard let firstDocument = firstVisibleDocument else { return }
        
        db.collection("users").document(userId).collection("checkIns")
            .order(by: "date", descending: false)
            .start(afterDocument: firstDocument)
            .limit(to: 5)
            .getDocuments { (querySnapshot, error) in
                guard let newDocuments = querySnapshot?.documents, !newDocuments.isEmpty else {
                    print("Error fetching previous documents: \(String(describing: error))")
                    return
                }
                let newEntries = newDocuments.compactMap { document -> CheckInData? in
                    try? document.data(as: CheckInData.self)
                }.sorted(by: { $0.date < $1.date })
                
                DispatchQueue.main.async {
                    self.checkInEntries = newEntries
                    self.firstVisibleDocument = newDocuments.last
                    self.lastVisibleDocument = newDocuments.first
                    self.canFetchPrevious = true
                    self.updateNextNav(userId: userId)
                }
            }
    }
    
}
