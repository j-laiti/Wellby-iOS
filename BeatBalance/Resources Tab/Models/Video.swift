//
//  Video.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/30/24.
//

import Foundation

struct Video: Decodable {
    
    var videoId = ""
    var title = ""
    var description = ""
    var thumbnail = ""
    var published = Date()
    
    enum CodingKeys: String, CodingKey {
        
        case snippet
        case published = "publishedAt"
        case title
        case description
        case thumbnails
        case high
        case thumbnail = "url"
        case resourceId
        case videoId
        
    }
    
    //default initialiser with dummy data
    init() {
        self.videoId = "12345"
        self.title = "I am a video"
        self.description = "This is a description igigigjg i jfkfddkdo eoeiwos sodroigj ao fujsj eoru nc srurjf"
        self.thumbnail = "https://i.ytimg.com/vi/6JHu3b-pbh8/sddefault.jpg"
        self.published = Date()
    }
    
    // initialiser that will allow me to set the data of a new video
    init(videoId: String, title: String, description: String, thumbnail: String, published: Date) {
        self.videoId = videoId
        self.title = title
        self.description = description
        self.thumbnail = thumbnail
        self.published = published
    }
    
    //custom decoder information
    init(from decoder: Decoder) throws {
        
        //define necessary containers
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let snippetContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .snippet)
        let thumbnailContainer = try snippetContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .thumbnails)
        let highThumbnailContainer = try thumbnailContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .high)
        let resourceContainer = try snippetContainer.nestedContainer(keyedBy: CodingKeys.self, forKey: .resourceId)
        
        //define vars
        self.published = try snippetContainer.decode(Date.self, forKey: .published)
        self.title = try snippetContainer.decode(String.self, forKey: .title)
        self.description = try snippetContainer.decode(String.self, forKey: .description)
        self.thumbnail = try highThumbnailContainer.decode(String.self, forKey: .thumbnail)
        self.videoId = try resourceContainer.decode(String.self, forKey: .videoId)
        
    }
}
