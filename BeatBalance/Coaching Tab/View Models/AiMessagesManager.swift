//
//  AiMessagesManager.swift
//  BeatBalance
//
//  Created by Justin Laiti on 11/17/24.
//

import Combine
import SwiftUI
import FirebaseFirestore
import Foundation

class AiMessagesManager: ObservableObject {
    @Published var aiMessages: [AiMessage] = []
    @Published var isLoading: Bool = false
    @Published var isRunActive: Bool = false
    
    private var threadID: String?
    private var userId: String
    
    let db = Firestore.firestore()
    
    init(userId: String) {
        self.userId = userId
        createThreadAndFetchMessages() // Fetch messages upon initialization
    }
    
    func createThreadAndFetchMessages() {
        let apiKey = PrivateKeys.openAIAPIKey

        // Check Firestore for an existing thread ID for this user
        db.collection("users").document(userId).collection("thread").document(userId).getDocument { document, error in
            if let document = document, document.exists, let threadID = document.data()?["threadID"] as? String {
                self.threadID = threadID
                self.fetchMessagesFromThread(threadID: threadID, apiKey: apiKey)
            } else {
                // If no existing thread, create a new one
                self.createThread(apiKey: apiKey) { [weak self] threadID in
                    guard let self = self, let threadID = threadID else { return }
                    self.threadID = threadID
                    
                    // Save the thread ID for this user in Firestore
                    self.db.collection("users").document(userId).collection("thread").document(userId).setData(["threadID": threadID], merge: true)
                    
                    self.fetchMessagesFromThread(threadID: threadID, apiKey: apiKey)
                }
            }
        }

    }
    
    func fetchMessagesFromThread(threadID: String, apiKey: String) {
        fetchMessagesFromThread(threadID: threadID, apiKey: apiKey) { [weak self] messages in
            guard let self = self, let messages = messages else { return }
            
            // Limit to the last 20 messages
            let recentMessages = Array(messages.suffix(20)).reversed()
            
            DispatchQueue.main.async {
                self.aiMessages = recentMessages.map { AiMessage(chatGPTMessage: $0) }
            }
        }
    }
    
    func sendMessage(text: String) {
        guard let threadID = threadID else { return }
        guard !isRunActive else {
            print("Cannot send message. A run is already active.")
            return
        }

        let apiKey = PrivateKeys.openAIAPIKey
        
        // add sent message to conversation first
        self.aiMessages.append(AiMessage(id: UUID().uuidString, text: text, received: false))
        
        // First, moderate the message
        moderateMessage(text) { [weak self] flagged, categories in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if flagged, let categories = categories, (categories["self-harm"] == true || categories["self-harm/intent"] == true || categories["self-harm/instructions"] == true || categories["violence"] == true) {
                    self.isLoading = true
                    let timestamp = Timestamp(date: Date())
                    
                    // Create data to log in Firestore
                    let flaggedMessage: [String: Any] = [
                        "userID": self.userId,
                        "message": text,
                        "categories": categories,
                        "timestamp": timestamp
                    ]
                    
                    // Save flagged message to Firestore
                    self.db.collection("flagged").addDocument(data: flaggedMessage) { error in
                        if let error = error {
                            print("Error saving flagged message to Firestore: \(error.localizedDescription)")
                        } else {
                            print("Flagged message saved successfully. User id:")
                        }
                    }
                    
                    // Invoke firebase func to text me
                    self.callFirebaseFunction(messageData: flaggedMessage) { result in
                        switch result {
                        case .success(let response):
                            print("Function Response: \(response)")
                        case .failure(let error):
                            print("Error calling function: \(error.localizedDescription)")
                        }
                    }

                    // Add user message and assistant response to the chat
                    
                    let flaggedResponse = "It sounds like you're going through a really tough time. It's important to talk to someone who can help you, like a friend, family member, or a professional. You don't have to go through this alone. Please consider reaching out for support. You can also find helpful resources linked on the previous screen. For your safety, this message has been flagged for review."

                    self.sendMessageInThread(threadID: threadID, message: flaggedResponse, role: "assistant", apiKey: apiKey) { success in
                        if success {
                            DispatchQueue.main.async {
                                // Append the flagged response to the conversation
                                self.aiMessages.append(AiMessage(id: UUID().uuidString, text: flaggedResponse, received: true))
                            }
                        }
                    }

                    self.isLoading = false
                    return
                }
                
                // If not flagged, proceed to send the message
                self.isLoading = true
                
                // Call the API to send the message
                self.sendMessageInThread(threadID: threadID, message: text, apiKey: apiKey) { success in
                    guard success else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                        }
                        return
                    }
                    self.createRunAndPoll(threadID: threadID, text: text)
                }
            }
        }
    }

    func createRunAndPoll(threadID: String, text: String, additionalInstructions: String? = nil) {
        guard !isRunActive else {
            print("Run is already active. Please wait.")
            return
        }

        let apiKey = PrivateKeys.openAIAPIKey
        let assistantID = PrivateKeys.openAIAssistantID
        DispatchQueue.main.async {
            self.isRunActive = true
        }
        createRun(threadID: threadID, assistantID: assistantID, apiKey: apiKey, additionalInstructions: additionalInstructions) { [weak self] run in
            guard let self = self else {
                return // Exit if self has been deallocated
            }
            
            guard let run = run else {
                DispatchQueue.main.async {
                    self.isRunActive = false // Clear the active run flag
                }
                return
            }

            self.pollRun(threadID: threadID, runID: run.id, apiKey: apiKey) { [weak self] response in
                guard let self = self else {
                    return // Exit if self has been deallocated
                }
                
                guard let response = response else {
                    DispatchQueue.main.async {
                        self.isRunActive = false // Clear the active run flag
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.aiMessages.append(AiMessage(id: UUID().uuidString, text: response, received: true))
                    self.isRunActive = false // Clear the active run flag
                }
            }
        }
    }

    
    // Include API functions here
    func createThread(apiKey: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Code: \(httpResponse.statusCode)")
            }
            
            if let thread = try? JSONDecoder().decode(ChatGPTThread.self, from: data) {
                completion(thread.id)
            } else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Failed to decode thread: \(responseString)")
                }
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func sendMessageInThread(threadID: String, message: String, role: String = "user", apiKey: String, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadID)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let messageData = ChatGPTRequest(role: role, content: message)
        
        guard let httpBody = try? JSONEncoder().encode(messageData) else {
            print("Failed to encode request body")
            completion(false)
            return
        }
        
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error)")
                completion(false)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Code: \(httpResponse.statusCode)")
            }
            
            if (response as? HTTPURLResponse)?.statusCode == 200 {
                completion(true)
            } else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                } else {
                    print("Failed to decode response")
                }
                completion(false)
            }
        }
        
        task.resume()
    }
    
    func createRun(threadID: String, assistantID: String, apiKey: String, additionalInstructions: String?, completion: @escaping (ChatGPTRun?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadID)/runs")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        var requestBody: [String: Any] = [
            "assistant_id": assistantID
        ]
        
        if let additionalInstructions = additionalInstructions {
            requestBody["additional_instructions"] = additionalInstructions
        }
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            print("Failed to encode request body")
            completion(nil)
            return
        }
        
        request.httpBody = httpBody
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Code: \(httpResponse.statusCode)")
            }
            
            if let run = try? JSONDecoder().decode(ChatGPTRun.self, from: data) {
                completion(run)
            } else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Failed to decode run: \(responseString)")
                }
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func fetchMessagesFromThread(threadID: String, apiKey: String, completion: @escaping ([ChatGPTMessage]?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadID)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch messages: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }
            
            if let chatResponse = try? JSONDecoder().decode(ChatGPTResponse.self, from: data) {
                completion(chatResponse.data)
            } else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Failed to decode messages: \(responseString)")
                }
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    func pollRun(threadID: String, runID: String, apiKey: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadID)/runs/\(runID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("assistants=v2", forHTTPHeaderField: "OpenAI-Beta")

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                print("Failed to fetch run status: \(error?.localizedDescription ?? "No data")")
                completion(nil)
                return
            }

            if let run = try? JSONDecoder().decode(ChatGPTRun.self, from: data) {
                if run.status == "completed" {
                    self.fetchMessagesFromThread(threadID: threadID, apiKey: apiKey) { messages in
                        guard let messages = messages else {
                            completion(nil)
                            return
                        }

                        // Find the assistant's response
                        if let assistantResponse = messages.first(where: { $0.role == "assistant" }) {
                            if let content = assistantResponse.content.first(where: { $0.type == "text" }) {
                                completion(content.text.value)
                            } else {
                                completion("No textual content from assistant.")
                            }
                        } else {
                            completion("No response from assistant.")
                        }
                    }
                } else if run.status == "pending" || run.status == "running" || run.status == "in_progress" {
                    // Poll again after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.pollRun(threadID: threadID, runID: runID, apiKey: apiKey, completion: completion)
                    }
                } else {
                    completion("Response failed to send, please try again")
                }
            } else {
                completion(nil)
            }
        }

        task.resume()
    }

    func moderateMessage(_ message: String, completion: @escaping (Bool, [String: Bool]?) -> Void) {
        let apiKey = PrivateKeys.openAIAPIKey
        let url = URL(string: "https://api.openai.com/v1/moderations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["input": message]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error in Moderation API call: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            guard let data = data else {
                print("No data received from Moderation API")
                completion(false, nil)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let results = (json["results"] as? [[String: Any]])?.first,
               let flagged = results["flagged"] as? Bool,
               let categories = results["categories"] as? [String: Bool] {
                completion(flagged, categories)
            } else {
                print("Failed to parse Moderation API response")
                completion(false, nil)
            }
        }
        task.resume()
    }

    func callFirebaseFunction(messageData: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        // Replace this URL with your Firebase Function URL
        guard let url = URL(string: "https://send-flagged-message-notification-5zmwi2nzna-uc.a.run.app") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 400, userInfo: nil)))
            return
        }
        
        var sanitizedData = messageData
        if let timestamp = messageData["timestamp"] as? Timestamp {
            sanitizedData["timestamp"] = timestamp.dateValue().ISO8601Format() // Convert to ISO8601 string
        }

        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert the messageData dictionary to JSON
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sanitizedData, options: [])
            request.httpBody = jsonData
        } catch {
            completion(.failure(error))
            return
        }
        
        // Make the network request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "No Response", code: 500, userInfo: nil)))
                return
            }

            // Parse response data
            switch httpResponse.statusCode {
            case 200:
                if let responseString = String(data: data, encoding: .utf8) {
                    completion(.success(responseString))
                } else {
                    completion(.failure(NSError(domain: "Invalid response format", code: 500, userInfo: nil)))
                }
            default:
                completion(.failure(NSError(domain: "HTTP Error", code: httpResponse.statusCode, userInfo: nil)))
            }
        }.resume()
    }
    
    func resetStates() {
        isLoading = false
        isRunActive = false
    }
    
    

}
