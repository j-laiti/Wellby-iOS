//
//  Settings.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/31/24.
//

import SwiftUI

struct Settings: View {
    @EnvironmentObject var userManager: AuthManager
    @EnvironmentObject var settings: UserSettings
    @State var showLogoutOptions = false
    @State private var showingColorInfoAlert = false
    @State private var showingColorInfoAlert2 = false
    @State private var showDeleteAccountOption = false
    @State private var isDarkModeEnabled = false
    @State private var showDeleteAlert = false
    
    @State private var newOptInValue: Bool = false
    @State private var showOptInConfirmationDialog = false
    @State private var isViewInitialized = false
    
    var body: some View {
        List {
            Section(header: Text("User Information")) {
                HStack(spacing: 20) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                    
                    if let user = userManager.currentUser {
                        VStack(alignment: .leading) {
                            Text("Name: \(user.firstName) \(user.surname)")
                                .font(.headline)
                            Text("Username: \(user.username)")
                                .foregroundStyle(.secondary)
                            if user.student {
                                Text("School: \(user.school)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("Error Loading user data")
                            .foregroundStyle(.red)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("Feedback Link") {
                Link("Send Feedback on Wellby", destination: URL(string: "https://forms.office.com/r/xVPbQQUs51")!)
            }
            
            Section("Custom Colours") {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        ColorPicker("App Components Colour", selection: $settings.primaryColor, supportsOpacity: false)
                            .onChange(of: settings.primaryColor) { newValue in
                                userManager.clickedOn(feature: "color_1")
                            }
                        Text("Used for buttons and interactive components (Avoid white or black)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(action: {
                        showingColorInfoAlert = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray) // Set this to a color that works well with both light and dark mode
                    }
                    .alert("Colour Selection", isPresented: $showingColorInfoAlert) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("Picking white or black may cause some components to not be visible in light/dark mode.")
                    }
                }
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        ColorPicker("App Background Colour", selection: $settings.secondaryColor, supportsOpacity: false)
                            .onChange(of: settings.secondaryColor) { newValue in
                                userManager.clickedOn(feature: "color_2")
                            }
                        Text("Used for background colour (Only when your phone is in light mode)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(action: {
                        showingColorInfoAlert2 = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.gray) // Set this to a color that works well with both light and dark mode
                    }
                    .alert("Color Selection", isPresented: $showingColorInfoAlert2) {
                        Button("OK", role: .cancel) { }
                    } message: {
                        Text("This is used for a few smaller components on the app. Again, picking white or black may cause some components to not be visible in all modes.")
                    }
                }
                
            }
            
            Section("MyToolKit Tab") {
                Toggle("Daily Quote Visible", isOn: $settings.displayQuote)
                    .onChange(of: settings.displayQuote) { newValue in
                        userManager.clickedOn(feature: "Display Quote")
                    }
            }
            
//            Section("Appearance") { // Add this section for appearance settings
//                Toggle("Dark Mode", isOn: $isDarkModeEnabled)
//                    .onChange(of: isDarkModeEnabled) { newValue in
//                        $settings.interfaceStyle = newValue ? .dark : .light
//                        // Apply the change to the entire app or specific views accordingly
//                        UIApplication.shared.windows.forEach { window in
//                            window.overrideUserInterfaceStyle = newValue ? .dark : .light
//                        }
//                    }
//            }
            
            Section("Chat Tab") {
                Toggle("Access a Human Health Coach", isOn: $newOptInValue)
                .onChange(of: newOptInValue) { newValue in
                    if isViewInitialized {
                        showOptInConfirmationDialog = true
                    }
                    userManager.clickedOn(feature: "healthCoachOpt")
                }
                .onAppear {
                    // Sync the toggle with the user's stored preference
                    if let currentUser = userManager.currentUser {
                        newOptInValue = currentUser.isCoachingOptedIn ?? false
                    }
                    // Mark the view as initialized after the first synchronization
                    DispatchQueue.main.async {
                        isViewInitialized = true
                    }
                }
                .alert(isPresented: $showOptInConfirmationDialog) {
                    Alert(
                        title: Text("Confirm Coaching"),
                        message: Text(newOptInValue ?
                            "Opting in to coaching will asign you a human coach who you can message about your wellbeing goals. Do you want to continue?" :
                            "Opting out will stop your access to health coaching. Are you sure you want to proceed?"
                        ),
                        primaryButton: .default(Text("Confirm"), action: {
                            userManager.applyOptInChange(newOptInValue)
                        }),
                        secondaryButton: .cancel {
                            newOptInValue.toggle()
                        }
                    )
                }
            }
            
            Section("Logging out") {
                Button {
                    showLogoutOptions.toggle()
                } label: {
                    Text("Logout")
                }.foregroundStyle(.red)
            }
            
            Section("Account Deletion") {
                Button {
                    showDeleteAlert.toggle()
                } label: {
                    Text("Delete Account")
                }
                .foregroundColor(.init(hex: "0xAC0000")) //maybe make this dark red?
                .bold()
                .alert("Are you sure you want to delete your account?", isPresented: $showDeleteAlert) {
                    Button("Yes, I'm sure") {
                        showDeleteAlert.toggle()
                        showDeleteAccountOption.toggle()
                    }
                    Button("No, cancel", role: .cancel) {
                    }
                }
                message: {
                    Text("This is irreversible and will delete all data associated with your account.")
                }
            }
            
        }
        .confirmationDialog("Logout", isPresented: $showLogoutOptions) {
            Button("Logout", role: .destructive) {
                Task {
                    do {
                        try await userManager.logout()
                    } catch {
                        print("logout unsuccessful")
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                showLogoutOptions = false
            }
        }
        .confirmationDialog("Are you sure you want to delete your account? All your data will be erased.", isPresented: $showDeleteAccountOption) {
            Button("Delete Account", role: .destructive) {
                Task {
                    do {
                        try await userManager.deleteUserAccount()
                    } catch {
                        print("delete account unsuccessful")
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                showDeleteAccountOption = false
            }
        }
        
    }
}

#Preview {
    Settings()
}
