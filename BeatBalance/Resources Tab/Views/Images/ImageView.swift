//
//  ImageView.swift
//  ResourcesPintrest
//
//  Created by Justin Laiti on 11/27/23.
//

import SwiftUI
import SafariServices

struct ImageView: View {
    @ObservedObject var resourceManager: ResourceManager
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var userManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
    @State var openWebsite = false
    @State private var isSaved = false
    
    var body: some View {
        VStack {
            if case .image(let selectedImage) = resourceManager.selectedResourceType {
                
                HStack {
                    Spacer()

                    Button {
                        if isSaved {
                            Task {
                                if let userId = userManager.currentUser?.id {
                                    try await resourceManager.deleteSavedResource(id: selectedImage.path, isImage: true, userId: userId)
                                }
                            }
                            isSaved = false
                        } else {
                            if let userId = userManager.currentUser?.id {
                                resourceManager.saveImage(path: selectedImage.path, url: selectedImage.url, topic: selectedImage.topic, userId: userId)
                                isSaved = true
                                userManager.clickedOn(feature: "Save image")
                            }
                        }
                        
                    } label: {
                        Image(systemName: isSaved ? "checkmark.square.fill" : "square.and.arrow.down")
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 30)
                .task {
                    await checkIfImageIsSaved(path: selectedImage.path)
                }
                
                
                Image(uiImage: selectedImage.uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(10)
                    .clipped()
                    .padding()
                
                Button("Open Website") {
                    openWebsite = true
                    userManager.clickedOn(feature: "Open website")
                }
                .padding(10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .circular))
                .shadow(radius: 5)
                .sheet(isPresented: $openWebsite, content: {
                    SafariView(url: URL(string: selectedImage.url) ?? URL(string: "https://spunout.ie/")!)
                })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            userManager.viewDidAppear(screen: "Image")
        }

    }
    
    func checkIfImageIsSaved(path: String) async {
        if let userId = userManager.currentUser?.id {
            isSaved = await resourceManager.isResourceSaved(id: path, isImage: true, userId: userId)
        }
    }
}

#Preview {
    ImageView(resourceManager: ResourceManager(selectedResourceType: .image(ImageData(uiImage: UIImage(named: "explore") ?? UIImage(systemName: "photo")!, url: "https://spunout.ie/"))))
}
