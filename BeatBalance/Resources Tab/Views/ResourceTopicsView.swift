//
//  ResourceTopicsView.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/30/24.
//

import SwiftUI

struct ResourceTopicsView: View {
    @ObservedObject var resourceManager: ResourceManager
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var userManager: AuthManager
    @State private var showTopicView = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
                        
            VStack(alignment: .leading) {
                VStack(alignment: .center) {
                    Text("Resources")
                        .bold()
                        .font(.title)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                
                Spacer()
                
                // Display recently viewed resource
                if let resourceType = resourceManager.selectedResourceType {
                    RecentlyViewed(resourceManager: resourceManager, resourceType: resourceType)
                }
                
                Spacer()
                
                // Research Topic Buttons
                Text("Explore Topics:")
                    .font(.title3)
                    .bold()
                
                ForEach(Constants.Topics.allCases, id: \.self) { topic in
                    Button(action: {
                        resourceManager.selectedTopic = topic
                        showTopicView = true
                    }) {
                        HStack {
                            Image(systemName: topic.systemImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20, alignment: .leading)
                                .foregroundColor(settings.primaryColor)

                            Text("\(topic.rawValue)")
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            Spacer()
                        }
                        .padding()
                        .frame(width: 250, height: 50)
                        .background(
                            Group {
                                if colorScheme == .light {
                                    Color.white
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                        )
                        .cornerRadius(10)
                        .shadow(radius: 5)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
            }
            .padding()
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
            .navigationDestination(isPresented: $showTopicView) {
                TopicView(resourceManager: resourceManager)
            }
        }
        .onAppear {
            userManager.viewDidAppear(screen: "Resources Overview")
        }
    }
}

