//
//  ImageGallery.swift
//  ResourcesLayout
//
//  Created by Justin Laiti on 12/4/23.
//

import SwiftUI

struct ImageGallery: View {
    @ObservedObject var resourceManager: ResourceManager
    @State private var imageClicked = false
    
    var body: some View {
        
        ScrollView {
            HStack(alignment:.top, spacing: 5) {
                LazyVStack(spacing: 10) {
                    ForEach(Array(resourceManager.images.prefix(Int(ceil(Double(resourceManager.images.count) / 2.0)))), id: \.self) { image in
                        Button {
                            imageClicked = true
                            resourceManager.selectedResourceType = .image(image)
                        } label: {
                            Image(uiImage: image.uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: UIScreen.main.bounds.width / 2 - 20)
                                .cornerRadius(10)
                                .clipped()
                        }
                    }
                }
                
                LazyVStack(spacing: 10) {
                    ForEach(Array(resourceManager.images.dropFirst(Int(ceil(Double(resourceManager.images.count) / 2.0)))), id: \.self) { image in
                        Button {
                            imageClicked = true
                            resourceManager.selectedResourceType = .image(image)
                        } label: {
                            Image(uiImage: image.uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: UIScreen.main.bounds.width / 2 - 20)
                                .cornerRadius(10)
                                .clipped()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $imageClicked, content: {
            ImageView(resourceManager: resourceManager)
        })
    }
}

#Preview {
    ImageGallery(resourceManager: ResourceManager())
}
