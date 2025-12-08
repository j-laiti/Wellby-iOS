//
//  RecentlyViewed.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 1/15/24.
//

import SwiftUI

struct RecentlyViewed: View {
    var resourceManager: ResourceManager
    var resourceType: ResourceType
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Recently Viewed:")
                .font(.title3)
                .bold()
            
            VStack(alignment: .trailing) {
                switch resourceType {
                case .video(let video):
                    VideoPreviewBlock(videoPreview: VideoPreview(video: video), resourceManager: resourceManager)
                case .image(let image):
                    NavigationLink {
                        ImageView(resourceManager: resourceManager)
                    } label: {
                        Image(uiImage: image.uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(10)
                            .clipped()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 250)
            }
        }
    }

//#Preview {
//    RecentlyViewed()
//}
