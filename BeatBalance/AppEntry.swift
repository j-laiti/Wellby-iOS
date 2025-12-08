//
//  AppEntry.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI

struct AppEntry: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    @StateObject var resourceManager = ResourceManager(selectedResourceType: .image(ImageData(uiImage: UIImage(named: "explore") ?? UIImage(systemName: "photo")!, url: "https://spunout.ie/")))
    @State private var showingTerms = UserDefaults.standard.bool(forKey: "TermsAccepted") == false
    
    var body: some View {
        TabView {
            Group {
                MyToolKit(resourceManager: resourceManager)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                ResourceTopicsView(resourceManager: resourceManager)
                    .tabItem {
                        Label("Resources", systemImage: "folder")
                    }
                
                BiofeedbackScreen()
                    .tabItem {
                        Label("HRV", systemImage: "heart.fill")
                    }
                
                ChatTabLazyLoader()
                    .tabItem {
                        Label("Chat", systemImage: "message")
                    }
            }
            .toolbarBackground(.visible, for: .tabBar)
            
        }
        .tint(settings.primaryColor)
        .background(Color.primary)
        .onAppear {
            NotificationManager.shared.checkForPermission()
        }
        .sheet(isPresented: $showingTerms) {
            TermsAndConditions(accepted: $showingTerms)
        }
    }
}

struct ChatTabLazyLoader: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        let chatManager = ChatManager(userManager: authManager)
        let aiMessagesManager = AiMessagesManager(userId: authManager.currentUser?.id ?? "user1234")
        
        ChatTabEntry(chatManager: chatManager)
            .environmentObject(aiMessagesManager)
    }
}
