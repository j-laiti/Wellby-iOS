//
//  TopicView.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 11/27/23.
//

import SwiftUI

struct TopicView: View {
    @ObservedObject var resourceManager: ResourceManager
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var userManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading) {
            //Topic title
            VStack(alignment: .center) {
                Text(resourceManager.selectedTopic.rawValue)
                    .bold()
                    .font(.title)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
            }
            
            //Video Scroll View
            Text("Videos")
                .padding(.top, 5)
                .font(.title2)
                .bold()
            
            // TODO: if no videos are returned, display something about no connection
            VideoRow(resourceManager: resourceManager)
                .frame(height: 200)
                .task {
                    resourceManager.getVideos()
                }
            
            //Grid of images scroll view
            Text("Images and Articles")
                .font(.title2)
                .bold()
                .padding(.vertical, 5)
            
            // TODO: if no videos are returned, display something about no connection
            ImageGallery(resourceManager: resourceManager)
                .task {
                    await resourceManager.getImages()
                }
            
            
        }
        .padding(.horizontal)
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
            userManager.viewDidAppear(screen: "Resource Topic")
        }
        
    }
}

#Preview {
    TopicView(resourceManager: ResourceManager())
}
