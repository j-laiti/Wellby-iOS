//
//  CacheManager.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 12/3/23.
//

import Foundation
import SwiftUI

class CacheManager {
    
    // video previews cache
    static var videoCache = [String: Data]()
    
    static func setVideoCache(_ url: String, _ data: Data?) {
        //store image data
        videoCache[url] = data
    }
    
    static func getVideoCache(_ url: String) -> Data? {
        return videoCache[url]
    }
    
    // image data cache
    static var imageCache = [String: ImageData]()
    
    static func setImageCache(_ path: String, _ imageData: ImageData) {
        //store image data
        imageCache[path] = imageData
    }
    
    static func getImageCache(_ path: String) -> ImageData? {
        return imageCache[path]
    }
    
    
    
}
