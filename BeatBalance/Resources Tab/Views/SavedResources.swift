//
//  SavedResources.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 1/15/24.
//

import SwiftUI

struct SavedResources: View {
    @ObservedObject var resourceManager: ResourceManager
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var userManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    @State var imageClicked = false
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .center) {
                Text("Resource Library")
                    .font(.title)
            }
            .frame(maxWidth: .infinity)
            
            Text("Saved Videos")
                .padding(.top, 5)
                .font(.title3)
                .bold()
            
            VideoRow(resourceManager: resourceManager)
                .frame(height: 200)
                .task {
                    if let userId = userManager.currentUser?.id {
                        await resourceManager.loadSavedVideos(userId: userId)
                    }
                }
            
            Text("Saved Images")
                .font(.title3)
                .bold()
            
            ImageGallery(resourceManager: resourceManager)
            .task {
                if let userId = userManager.currentUser?.id {
                    await resourceManager.loadSavedImages(userId: userId)
                }
            }
        }
        .sheet(isPresented: $imageClicked, content: {
            ImageView(resourceManager: resourceManager)
        })
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
            userManager.viewDidAppear(screen: "Saved Resources")
        }
    }
}

#Preview {
    SavedResources(resourceManager: ResourceManager())
}
