//
//  VideoView.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 11/27/23.
//

import SwiftUI

struct VideoView: View {
    @ObservedObject var resourceManager: ResourceManager
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var userManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    var video: Video
    var date: String {
        //create a formatted date from the videos date
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d, yyyy"
        return df.string(from: video.published)
    }
    @State private var isSaved = false
    
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Spacer()

                    Button {
                        if let userId = userManager.currentUser?.id {
                            if isSaved {
                                Task {
                                    try await resourceManager.deleteSavedResource(id: video.videoId, isImage: false, userId: userId)
                                }
                                isSaved = false
                            } else {
                                resourceManager.saveVideo(video: video, userId: userId)
                                isSaved = true
                                userManager.clickedOn(feature: "Save video")
                            }
                        }
                     
                    } label: {
                        Image(systemName: isSaved ? "checkmark.square.fill" : "square.and.arrow.down")
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 20)
                .task {
                    await checkIfVideoIsSaved(videoId: video.videoId)
                }
                
                //video title
                Text(video.title)
                    .bold()
                
                //date
                Text(date)
                    .foregroundColor(.gray)
                
                //video
                YoutubeVideoPlayer(video: video)
                    .aspectRatio(CGSize(width: geometry.size.width, height: geometry.size.width * 9 / 16), contentMode: .fit)
                
                //video description
                ScrollView {
                    Text(video.description)
                }
            }
            .font(.system(size: 19))
            .padding()
        .padding(.top, 40)
        }
        .background(
            Group {
                if colorScheme == .light {
                    LinearGradient(gradient: Gradient(colors: [settings.secondaryColor.opacity(0.7), .white]), startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                } else {
                    Color.clear
                        .ignoresSafeArea()
                }
            }
        )
        .onAppear {
            userManager.viewDidAppear(screen: "Video")
        }
    }
    
    func checkIfVideoIsSaved(videoId: String) async {
        if let userId = userManager.currentUser?.id {
            isSaved = await resourceManager.isResourceSaved(id: videoId, isImage: false, userId: userId)
        }
    }
}

#Preview {
    VideoView(resourceManager: ResourceManager(), video: Video())
}
