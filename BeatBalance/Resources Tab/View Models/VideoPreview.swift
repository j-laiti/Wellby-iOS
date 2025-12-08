//
//  VideoPreview.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 12/3/23.
//

import Foundation
import Alamofire

class VideoPreview: ObservableObject {
    
    @Published var thumbnailData = Data()
    @Published var title: String
    
    var video: Video
    
    init(video: Video) {
        
        //set video and title
        self.video = video
        self.title = video.title
        
        //download the image data
        guard video.thumbnail != "" else { return }
        
        //check cache to see if data already exists
        if let cachedData = CacheManager.getVideoCache(video.thumbnail) {
            //set thumbnail data
            thumbnailData = cachedData
            return
        }
        
        guard let url = URL(string: video.thumbnail) else { return }
        
        AF.request(url).validate().responseData { response in
                
            if let data = response.data {
                //save thumbnail data in cache
                CacheManager.setVideoCache(video.thumbnail, data)
                
                //set image data
                DispatchQueue.main.async {
                    self.thumbnailData = data
                }
            }
        }
    }
}
