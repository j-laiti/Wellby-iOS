//
//  VideoManager.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 12/1/23.
//

import SwiftUI
import Alamofire
import Firebase
import FirebaseFirestore
import FirebaseStorage

// Make the class conform to Sendable
@MainActor
final class ResourceManager: ObservableObject, @unchecked Sendable {
    //video variables
    @Published var videos = [Video]()
    
    //selection tracker
    @Published var selectedTopic: Constants.Topics = .stress
    
    @Published var selectedResourceType: ResourceType?
    
    // Dictionary to hold page tokens for each topic
    private var pageTokens: [Constants.Topics: (currentToken: String?, nextToken: String?, startIndex: Int, date: Date?)] = [:] {
        didSet {
            saveTokensToUserDefaults()
        }
    }
    
    //user data
    var currentUserId: String?
    
    //image data
    @Published var images = [ImageData]()
    @Published var savedImages = [ImageData]()
    
    //firestore database - make private and immutable
    private let db = Firestore.firestore()
    
    // initializer to allow for preview images
    init(selectedResourceType: ResourceType? = nil) {
        self.selectedResourceType = selectedResourceType
        loadTokensFromUserDefaults()
    }

    // functions for saving video tokens
    private func saveTokensToUserDefaults() {
        let tokenDict = pageTokens.reduce(into: [String: [String: Any]]()) { result, entry in
            let (topic, data) = entry
            result[topic.rawValue] = [
                "currentToken": data.currentToken ?? "",
                "nextToken": data.nextToken ?? "",
                "startIndex": data.startIndex,
                "date": data.date ?? Date.distantPast
            ]
        }
        UserDefaults.standard.set(tokenDict, forKey: "PageTokensWithDates")
    }

    private func loadTokensFromUserDefaults() {
        if let savedData = UserDefaults.standard.dictionary(forKey: "PageTokensWithDates") as? [String: [String: Any]] {
            pageTokens = Constants.Topics.allCases.reduce(into: [:]) { result, topic in
                if let data = savedData[topic.rawValue],
                   let currentToken = data["currentToken"] as? String,
                   let nextToken = data["nextToken"] as? String,
                   let startIndex = data["startIndex"] as? Int,
                   let dateValue = data["date"] as? Date {
                    let date = dateValue == Date.distantPast ? nil : dateValue
                    result[topic] = (currentToken: currentToken, nextToken: nextToken, startIndex: startIndex, date: date)
                } else {
                    result[topic] = (nil, nil, 0, nil)
                }
            }
        }
    }
    
    // 1. make youtube api request for a given playlist
    func getVideos() {
        // Capture necessary values to avoid capturing self
        let currentTopic = self.selectedTopic
        let currentTokenData = self.pageTokens[currentTopic]
        
        // Check if enough time has passed to use the nextPageToken
        let useNextToken: Bool
        if let lastUpdate = currentTokenData?.date {
            useNextToken = Date().timeIntervalSince(lastUpdate) >= 86400 // seconds in a day
        } else {
            useNextToken = false
            // Initialize date on first selection
            Task { @MainActor in
                self.pageTokens[currentTopic] = (nil, nil, 0, Date())
            }
        }
        
        // clear any existing videos
        Task { @MainActor in
            self.videos = []
        }
        
        // Set the token for fetching videos
        let tokenToUse = useNextToken ? currentTokenData?.nextToken : currentTokenData?.currentToken
        
        //define the youtube API endpoint
        let url = Constants.listURL
        let playlistID = currentTopic.playlistId()
        
        //define decoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Parameters without pageToken
        var parameters: [String: String] = [
            "part": "snippet",
            "playlistId": playlistID,
            "key": Constants.youtubeAPIKey,
            "maxResults": "3" // Fetch 3 videos at a time
        ]
        
        // If we have a nextPageToken, add it to the request
        if let token = tokenToUse {
            parameters["pageToken"] = token
        }

        //use Alamofire to make the request
        AF.request(url, parameters: parameters)
            .validate()
            .responseDecodable(of: YTResponse.self, decoder: decoder) { [weak self] response in
                guard let self = self else { return }
                
                //check that the response was successful
                switch response.result {
                case .success(let data):
                    Task { @MainActor in
                        self.videos = data.items // Replace with new videos
                        
                        // Update the tokens
                        if useNextToken {
                            // Move nextToken to currentToken, set new nextToken and update the timestamp
                            self.pageTokens[currentTopic] = (
                                currentToken: self.pageTokens[currentTopic]?.nextToken,
                                nextToken: data.nextPageToken,
                                startIndex: self.pageTokens[currentTopic]?.startIndex ?? 0,
                                date: Date()
                            )
                        } else if self.pageTokens[currentTopic]?.nextToken == nil {
                            // First time loading, set nextToken only
                            self.pageTokens[currentTopic]?.nextToken = data.nextPageToken
                        }
                    }
                case .failure(let error):
                    print(error)
                    return
                }
            }
    }
    
    // 2. get image data from Firebase
    func getImages() async {
        await MainActor.run {
            self.images = []
        }
        
        //if selected topic is saved resources, fetch the saved images and break
        let currentTopic = self.selectedTopic
        let imagesPath = currentTopic.imagesPath()
        let batchSize = 4
        let tokenData = pageTokens[currentTopic] ?? (nil, nil, 0, Date())
        var startIndex = tokenData.startIndex
        let lastUpdate = tokenData.date
        
        do {
            // Step 1: Check the total number of images in the folder
            let totalImages = try? await countImagesInFolder(imagesPath)
            guard let totalImages = totalImages, totalImages > 0 else {
                print("No images found in the folder.")
                return
            }
            
            // Step 2: Check if it's time to update the batch
            if let lastUpdate = lastUpdate, Date().timeIntervalSince(lastUpdate) >= 86400 {
                print("over time since last check")
                // Move to the next batch or reset to the start
                if startIndex + (2*batchSize) <= totalImages {
                    startIndex += batchSize
                    print("update start index! \(startIndex)")
                } else {
                    print("set start index to 0")
                    startIndex = 0 // Reset to the beginning
                }
                await MainActor.run {
                    self.pageTokens[currentTopic] = (tokenData.currentToken, tokenData.nextToken, startIndex, Date())
                }
            } else if lastUpdate == nil {
                await MainActor.run {
                    self.pageTokens[currentTopic] = (tokenData.currentToken, tokenData.nextToken, startIndex, Date())
                }
            }
            
            // Step 3: Build the query for the required batch of images
            let dbRef = self.db // Local reference to avoid capturing self
            var query = dbRef.collection(imagesPath)
                .order(by: "date")

            if startIndex > 0 {
                // Fetch up to the `startIndex` to determine the starting document
                let intermediateQuerySnapshot = try await dbRef.collection(imagesPath)
                    .order(by: "date")
                    .limit(to: startIndex)
                    .getDocuments()

                if let lastDocument = intermediateQuerySnapshot.documents.last {
                    // Modify the query to start after the last document
                    query = query.start(afterDocument: lastDocument)
                }
            }

            // Limit the query to fetch only the required batch
            query = query.limit(to: batchSize)

            let batchSnapshot = try await query.getDocuments()
            for document in batchSnapshot.documents {
                if let imagePath = document.data()["imageData"] as? String,
                   let imageURL = document.data()["url"] as? String {
                    await loadImage(from: imagePath, with: imageURL, topic: currentTopic.rawValue)
                }
            }
        } catch {
            print("Error fetching images \(error)")
        }
    }
    
    // Count the total number of images in the folder
    private func countImagesInFolder(_ path: String) async throws -> Int {
        let dbRef = self.db // Local reference to avoid capturing self
        let querySnapshot = try await dbRef.collection(path).getDocuments()
        return querySnapshot.count
    }
    
    // 3. check cache and load images
    func loadImage(from path: String, with url: String, topic: String) async {
        if let imageCache = CacheManager.getImageCache(path) {
            await MainActor.run {
                self.images.append(imageCache)
            }
            return
        }
        
        let pathReference = Storage.storage().reference(withPath: path)
        
        do {
            // Use task-based API instead of completion handler
            let data = try await pathReference.data(maxSize: 5 * 1024 * 1024)
            if let image = UIImage(data: data) {
                let newImage = ImageData(uiImage: image, url: url, topic: topic, path: path)
                
                CacheManager.setImageCache(path, newImage) // save image data to cache
                
                await MainActor.run {
                    self.images.append(newImage)
                }
            }
        } catch {
            print("Error getting image data: \(error)")
        }
    }
    
    func saveImage(path: String, url: String, topic: String, userId: String) {
        // prepare array of data to save
        let imageData: [String: Any] = ["path": path, "url": url, "topic": topic]
        
        let dbRef = self.db // Local reference to avoid capturing self
        
        //write this data to a saved resource collection in Firestore
        dbRef.collection("users").document(userId).collection("images").addDocument(data: imageData) { error in
            if let error = error {
                print("error sending saved resources: \(error)")
            } else {
                print("Resource saved!!")
            }
        }
    }
    
    func loadSavedImages(userId: String) async {
        await MainActor.run {
            self.images = []
        }
        
        let dbRef = self.db // Local reference to avoid capturing self
        
        do {
            let querySnapshot = try await dbRef.collection("users").document(userId).collection("images").getDocuments()
            
            for document in querySnapshot.documents {
                let data = document.data()
                let path = data["path"] as? String ?? ""
                let url = data["url"] as? String ?? ""
                let topic = data["topic"] as? String ?? ""

                // Load the image from Firebase Storage
                await self.loadImage(from: path, with: url, topic: topic)
            }
            
        } catch {
            print("Error getting saved images: \(error)")
        }
    }
    
    func isResourceSaved(id: String, isImage: Bool, userId: String) async -> Bool {
        let dbRef = self.db // Local reference to avoid capturing self
        
        do {
            var resourceType = ""
            var fieldName = ""
            
            // set path variables based on resource type
            if isImage {
                resourceType = "images"
                fieldName = "path"
            } else {
                resourceType = "videos"
                fieldName = "videoId"
            }
            
            // make firestore call to retrieve docs
            let querySnapshot = try await dbRef.collection("users")
                .document(userId)
                .collection(resourceType)
                .whereField(fieldName, isEqualTo: id)
                .getDocuments()
                
            return !(querySnapshot.documents.isEmpty)
            
        } catch {
            print("Error checking for saved resource: \(error)")
            return false
        }
    }
    
    func deleteSavedResource(id: String, isImage: Bool, userId: String) async throws {
        let dbRef = self.db // Local reference to avoid capturing self
        
        var resourceType = ""
        var fieldName = ""
        
        // set path variables based on resource type
        if isImage {
            resourceType = "images"
            fieldName = "path"
        } else {
            resourceType = "videos"
            fieldName = "videoId"
        }
        
        let querySnapshot = try await dbRef.collection("users").document(userId)
                                       .collection(resourceType)
                                       .whereField(fieldName, isEqualTo: id)
                                       .getDocuments()
        
        for document in querySnapshot.documents {
            try await document.reference.delete()
        }
    }
    
    func saveVideo(video: Video, userId: String) {
        // convert the date to a timestamp
        let timestamp = Timestamp(date: video.published)
        
        // prepare the data to send to firestore
        let videoData: [String: Any] = [
            "videoId": video.videoId,
            "title": video.title,
            "description": video.description,
            "thumbnail": video.thumbnail,
            "published": timestamp
        ]
        
        let dbRef = self.db // Local reference to avoid capturing self
        
        // write this data to firestore
        dbRef.collection("users").document(userId).collection("videos").addDocument(data: videoData) { error in
            if let error = error {
                print("error sending saved resources: \(error)")
            } else {
                print("Resource saved!!")
            }
        }
    }
    
    func loadSavedVideos(userId: String) async {
        await MainActor.run {
            self.videos = []
        }
        
        let dbRef = self.db // Local reference to avoid capturing self
        
        do {
            let querySnapshot = try await dbRef.collection("users").document(userId).collection("videos").getDocuments()
            
            var newVideos = [Video]() // Local collection to avoid multiple UI updates
            
            for document in querySnapshot.documents {
                let data = document.data()
                let videoId = data["videoId"] as? String ?? ""
                let title = data["title"] as? String ?? ""
                let description = data["description"] as? String ?? ""
                let thumbnail = data["thumbnail"] as? String ?? ""
                let publishedTimestamp = data["published"] as? Timestamp ?? Timestamp()
                let publishedDate = publishedTimestamp.dateValue()
                
                let video = Video(videoId: videoId, title: title, description: description, thumbnail: thumbnail, published: publishedDate)
                newVideos.append(video)
            }
            
            await MainActor.run {
                self.videos = newVideos
            }
            
        } catch {
            print("Error getting saved videos: \(error)")
        }
    }
    
    func deleteSavedVideo(videoId: String, userId: String) async throws {
        let dbRef = self.db // Local reference to avoid capturing self
        
        let querySnapshot = try await dbRef.collection("users").document(userId)
                                       .collection("videos")
                                       .whereField("videoId", isEqualTo: videoId)
                                       .getDocuments()
        for document in querySnapshot.documents {
            try await document.reference.delete()
        }
    }
}
