//
//  VideoPreviewBlock.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 12/3/23.
//

import SwiftUI

struct VideoPreviewBlock: View {
    @ObservedObject var videoPreview: VideoPreview
    @ObservedObject var resourceManager: ResourceManager
    @State var detailViewPresented = false
    
    var body: some View {
            Button{
                detailViewPresented.toggle()
                resourceManager.selectedResourceType = .video(videoPreview.video)
                print("pressed")
            } label: {
                VStack(alignment: .leading) {
                        //display image
                        Image(uiImage: UIImage(data: videoPreview.thumbnailData) ?? UIImage())
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 100, idealWidth: .infinity, maxWidth: .infinity,
                                    minHeight: 100, idealHeight: 275 * 9 / 16, maxHeight: 275 * 9 / 16)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        //display the title
                        Text(videoPreview.title)
                            .bold()
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundStyle(.gray)
                    }
                .frame(width: 275)
                .padding(.trailing, 10)
            }
            .sheet(isPresented: $detailViewPresented, content: {
                VideoView(resourceManager: resourceManager, video: videoPreview.video)
            })
    }
    
}

#Preview {
    VideoPreviewBlock(videoPreview: VideoPreview(video: Video()), resourceManager: ResourceManager())
}
