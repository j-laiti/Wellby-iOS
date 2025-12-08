//
//  ContentView.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI
import Firebase

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if authManager.userSession != nil && !isLoading {
                AppEntry()
            } else if isLoading {
                // Display a loading indicator or custom view here
                ProgressView("Loading...")
                    .onAppear {
                        loadData()
                    }
            } else {
                SignIn()
            }

        }
    }
    
    private func loadData() {
        guard authManager.userSession?.uid != nil else {
            isLoading = false
            return
        }
        // Simulate data fetching or wait for real data loading logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Simulated delay
            isLoading = false
        }
    }

}

