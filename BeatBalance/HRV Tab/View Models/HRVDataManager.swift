//
//  HRVDataManager.swift
//  BeatBalance
//
//  Created by Justin Laiti on 4/14/24.
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

class HRVDataManager: ObservableObject {
    static let shared = HRVDataManager()
    @Published var isConnectedToInternet = true
    @Published var latestHRVData: HRVSessionData?
    @Published var hrvDataList: [HRVSessionData] = []
    
    private var rawPPGBatch: [String] = []
    private let maxBatchSize = 30
    
    private var currentUserID = ""
    
    private var cancellables = Set<AnyCancellable>()
    let db = Firestore.firestore()
    
    @Published var calibrationRecordCount: Int = 0
    @Published var isLoadingRelaxScale: Bool = false
    @Published var relaxScaleError: String? = nil
    
    @Published var isProcessingData: Bool = false
    
    private init() {}
    
    func fetchLatestHRVData(userID: String) {
        self.currentUserID = userID
        isLoadingRelaxScale = true // Start loading
        relaxScaleError = nil // Reset any previous errors

        let hrvDataRef = db.collection("users").document(userID).collection("HRV-inApp")

        hrvDataRef.order(by: "timestamp", descending: true).limit(to: 1)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        print("Error retrieving documents: \(error)")
                        self.relaxScaleError = "Unable to load recent data."
                        self.isLoadingRelaxScale = false // Stop loading
                        return
                    }

                    if let documents = querySnapshot?.documents, let latestDoc = documents.first {
                        do {
                            var sessionData = try latestDoc.data(as: HRVSessionData.self)
                            sessionData.id = latestDoc.documentID // Assign Firestore document ID to the id field
                            self.latestHRVData = sessionData
//                            print("Fetched HRV Data: \(sessionData)")
                        } catch {
                            print("Error decoding session data: \(error)")
                            self.relaxScaleError = "Unable to load recent data."
                        }
                    } else {
                        print("No HRV data found for user \(userID)")
                        self.relaxScaleError = "No data available."
                    }
                    self.isLoadingRelaxScale = false // Stop loading
                }
            }
    }
    
    func fetchHRVData(userID: String, limit: Int = 5) {
        let hrvDataRef = db.collection("users").document(userID).collection("HRV-inApp")
        hrvDataRef.order(by: "timestamp", descending: true).limit(to: limit)
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        print("Error retrieving documents: \(error)")
                    } else {
                        guard let documents = querySnapshot?.documents else { return }
                        let decodedData = documents.compactMap { doc -> HRVSessionData? in
                            do {
                                var sessionData = try doc.data(as: HRVSessionData.self)
                                sessionData.id = doc.documentID // Assign Firestore document ID to the id field
                                return sessionData
                            } catch {
                                print("Error decoding document \(doc.documentID): \(error)")
                                return nil
                            }
                        }
                        
                        self.hrvDataList = Array(Set(decodedData)) // Remove duplicates if any
                    }
                }
            }
    }

    private func processMultipleDocuments(_ documents: [QueryDocumentSnapshot]?) {
        do {
            let hrvDataList = try documents?.map { try $0.data(as: HRVSessionData.self) }
            Task { @MainActor in
                self.hrvDataList = hrvDataList ?? []
            }
        } catch {
            print("Error decoding HRV data: \(error)")
        }
    }
    
    func createSessionDocument(userID: String, sessionID: String) {
        self.currentUserID = userID
        
        let docRef = db.collection("users").document(userID).collection("HRV-inApp").document(sessionID)
        
        docRef.setData([
            "timestamp": FieldValue.serverTimestamp(),
            "status": "recording"
        ]) { error in
            if let error = error {
                print("Error creating session document: \(error.localizedDescription)")
            } else {
                print("Session document created successfully for \(sessionID)")
            }
        }
    }
    
    func flushRawDataBuffer(sessionID: String) {
        guard !rawPPGBatch.isEmpty else {
            print("No remaining data to flush")
            return
        }
        
        let batchData = rawPPGBatch.joined(separator: ",")
        
        let docRef = db.collection("users").document(currentUserID).collection("HRV-inApp").document(sessionID).collection("rawData").document()
        
        docRef.setData(["rawData": batchData, "timestamp": FieldValue.serverTimestamp()]) { [weak self] error in
            if let error = error {
                print("Error flushing raw PPG data: \(error.localizedDescription)")
            } else {
                print("Remaining raw PPG data flushed successfully.")
                self?.rawPPGBatch.removeAll()
            }
        }
    }
    
    func uploadRawDataToFirebase(sessionID: String, data: Data) {
        // Convert to hex string
        let hexString = data.map { String(format: "%02x", $0) }.joined()
        
        // Regular expression to capture two bytes (reading) + delimiter
        // Consider using a more efficient approach than regex for performance
        do {
            let regexPattern = "(\\w{4})(fe)"  // Matches exactly 2 bytes + "fe" delimiter
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            
            // Find all matches in hexString
            let matches = regex.matches(in: hexString, options: [], range: NSRange(location: 0, length: hexString.utf16.count))
            let readings = matches.map {
                String(hexString[Range($0.range(at: 1), in: hexString)!])
            }
            
            // Append each reading individually to the batch
            rawPPGBatch.append(contentsOf: readings)
            print("Reading added: \(readings)")

            if rawPPGBatch.count >= maxBatchSize {
                // Convert batch array to single string or structured data as needed
                let batchData = rawPPGBatch.joined(separator: ",")

                let docRef = db.collection("users").document(currentUserID).collection("HRV-inApp").document(sessionID).collection("rawData").document()

                docRef.setData(["rawData": batchData, "timestamp": FieldValue.serverTimestamp()]) { error in
                    if let error = error {
                        print("Error uploading raw PPG batch data: \(error.localizedDescription)")
                    } else {
                        print("Raw PPG batch data uploaded successfully.")
                    }
                }
                rawPPGBatch.removeAll()  // Clear the batch after sending
            }
        } catch {
            print("Error processing PPG data: \(error)")
        }
    }
    
    func uploadCalibrationData(userID: String, recordingID: String) {
        // check how many documents have the isCalibration = true
        if calibrationRecordCount < 4 {
            let userCollection = db.collection("users").document(userID).collection("HRV-inApp")
                
            // Query the most recent calibration entry
            userCollection
                .whereField("isCalibration", isEqualTo: true)
                .order(by: "timestamp", descending: true)
                .limit(to: 1)
                .getDocuments { [weak self] (querySnapshot, error) in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error fetching latest calibration entry: \(error.localizedDescription)")
                        return
                    }
                    
                    let now = Date()
                    if let documents = querySnapshot?.documents, let latestDoc = documents.first {
                        // Get the timestamp from the latest calibration document
                        if let timestamp = latestDoc.data()["timestamp"] as? Timestamp {
                            let lastCalibrationDate = timestamp.dateValue()
                            let hoursSinceLastCalibration = now.timeIntervalSince(lastCalibrationDate) / 3600
                            
                            if hoursSinceLastCalibration < 12 {
                                print("Calibration update skipped: only \(hoursSinceLastCalibration) hours since last calibration.")
                                return
                            }
                        }
                    }
                    
                    // If no recent calibration or enough time has passed, set isCalibration to true
                    let docRef = userCollection.document(recordingID)
                    docRef.setData(["isCalibration": true, "timestamp": Timestamp(date: now)], merge: true) { error in
                        if let error = error {
                            print("Error setting document with isCalibration: \(error.localizedDescription)")
                        } else {
                            print("isCalibration field added successfully for recording \(recordingID)")
                            // Update local calibration count on main thread
                            Task { @MainActor in
                                self.calibrationRecordCount += 1
                            }
                        }
                    }
                }
        } else {
            print("Calibration limit reached; no update required for recording \(recordingID)")
        }
    }

    func checkCalibrationProgress(userID: String) {
        let hrvDataRef = db.collection("users").document(userID).collection("HRV-inApp")
        
        // test filtering based on the # of isCalibration
        hrvDataRef.whereField("isCalibration", isEqualTo: true)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let error = error {
                        print("Error counting calibration documents: \(error)")
                    } else {
                        let count = querySnapshot?.documents.count ?? 0
                        print("Calibration count: \(count)")
                        self.calibrationRecordCount = count
                    }
                }
            }
    }
    
    private let firebaseFunctionURL = PrivateKeys.firebasePPGFunctionURL
    
    func remotePpgProcessing(participantID: String, hrvDocumentID: String, completion: @escaping ([String: Any]?) -> Void) {
        print("Started remote processing")
        
        Task { @MainActor in
            self.isProcessingData = true
        }
        
        guard var urlComponents = URLComponents(string: firebaseFunctionURL) else {
            Task { @MainActor in
                self.isProcessingData = false
            }
            completion(nil)
            return
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "participant_id", value: participantID),
            URLQueryItem(name: "hrv_document_id", value: hrvDocumentID)
        ]
        
        guard let url = urlComponents.url else {
            Task { @MainActor in
                self.isProcessingData = false
            }
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Use async/await pattern for better clarity and thread management
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                
                let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                Task { @MainActor in
                    self.isProcessingData = false
                }
                
                if let errorMessage = jsonObject?["error"] as? String {
                    print("Error from Firebase function: \(errorMessage)")
                    completion(nil)
                } else {
                    completion(jsonObject)
                }
            } catch {
                print("Error in remote processing: \(error)")
                
                Task { @MainActor in
                    self.isProcessingData = false
                }
                
                completion(nil)
            }
        }
    }
}
