//
//  YTResponse.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/30/24.
//

import Foundation

struct YTResponse: Decodable {
    
    var items: [Video]
    var nextPageToken: String?
    
    enum CodingKeys: String, CodingKey {
        
        case items
        case nextPageToken
        
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.items = try container.decode([Video].self, forKey: .items)
        
        self.nextPageToken = try container.decodeIfPresent(String.self, forKey: .nextPageToken)
        
    }
}
