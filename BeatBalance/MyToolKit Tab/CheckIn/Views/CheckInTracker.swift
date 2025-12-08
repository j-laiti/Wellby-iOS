//
//  CheckInTracker.swift
//  BeatBalance
//
//  Created by Justin Laiti on 2/26/24.
//

import SwiftUI
import Charts

struct CheckInTracker: View {
    @EnvironmentObject var userManager: AuthManager
    @ObservedObject var checkInManager: CheckInManager
    @EnvironmentObject var settings: UserSettings
    @Environment(\.colorScheme) var colorScheme
    @State var openWebsite = false
    
    var body: some View {
        
        VStack {
            Text("Check-in Tracker")
                .font(.title)
                .bold()
                .padding()
            
            TrackerBlock(checkInManager: checkInManager)
                .padding(5)
                .background(
                    Group {
                        if colorScheme == .light {
                            Color.white
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    })
                .cornerRadius(25)
                .shadow(radius: 5)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Button("Emotion Wheel") {
                openWebsite = true
            }
            .padding(15)
            .background(
                Group {
                    if colorScheme == .light {
                        Color.white
                    } else {
                        Color.gray.opacity(0.3)
                    }
                })
            .cornerRadius(25)
            .shadow(radius: 5)
            .sheet(isPresented: $openWebsite, content: {
                SafariView(url: URL(string: "https://www.6seconds.org/2022/03/13/plutchik-wheel-emotions/")!)
            })
            .padding()
            .onTapGesture {
                userManager.clickedOn(feature: "emotion wheel")
            }
            
            
            
            
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
            userManager.viewDidAppear(screen: "Checkin Summary")
        }
        
    }
}

