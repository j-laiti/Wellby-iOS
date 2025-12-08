//
//  MyToolKit.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/30/24.
//

import SwiftUI

struct MyToolKit: View {
    @EnvironmentObject var userManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    @ObservedObject var resourceManager: ResourceManager
    @Environment(\.colorScheme) var colorScheme
        
    var body: some View {
        let greeting = timeBasedGreeting()
        
        NavigationStack {
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                    
                    // Settings
                    NavigationLink {
                        Settings()
                    } label: {
                        Image(systemName: "gear")
                            .font(.title3)
                    }
                    .foregroundStyle(.primary)
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                
                // Greeting
                if let userName = userManager.currentUser?.firstName {
                    Text(greeting + userName)
                        .bold()
                        .font(.title)
                        .foregroundStyle(.primary)
                } else {
                    Text(greeting)
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .bold()
                }
                
                Spacer()
                
                // Quote
                if settings.displayQuote {
                    DailyQuote()
                        .frame(maxWidth: .infinity)
                }
                
                Spacer()
                
                //Check In
                CheckInEntryBlock()
                
                Spacer()
                
                // Calendar
                WeekView()
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Saved resources
                NavigationLink(destination: SavedResources(resourceManager: resourceManager)) {
                    HStack {
                        Image(systemName: "books.vertical")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .foregroundColor(settings.primaryColor)
                        
                        Text("Saved Resources")
                            .fontWeight(.medium)
                            .foregroundStyle(Color.primary)
                    }
                    .padding()
                    .background(
                        Group {
                            if colorScheme == .light {
                                Color.white
                            } else {
                                Color.gray.opacity(0.3)
                            }
                        })
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                
                Spacer()

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
        }
        .onAppear {
            userManager.viewDidAppear(screen: "ToolKit")
        }
        
    }
    
    func timeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 4..<12:
            return "Good Morning, "
        case 12..<17:
            return "Good Afternoon, "
        case 17..<24:
            return "Good Evening, "
        default:
            return "Hello, "
        }
    }
}

#Preview {
    MyToolKit(resourceManager: ResourceManager())
}
