//
//  VideoRow.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 12/3/23.
//

import SwiftUI

struct VideoRow: View {
    @ObservedObject var resourceManager: ResourceManager
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(resourceManager.videos.prefix(6), id:\.videoId) {video in
                    VideoPreviewBlock(videoPreview: VideoPreview(video: video), resourceManager: resourceManager)
                }
            }
        }
    }
}

#Preview {
    VideoRow(resourceManager: ResourceManager())
}
