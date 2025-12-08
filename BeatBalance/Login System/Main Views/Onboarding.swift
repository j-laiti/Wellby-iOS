//
//  Onboarding.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI

struct Onboarding: View {
    @State var firstName = ""
    @State var surname = ""
    @State var username = ""
    @State var email = ""
    @State var password = ""
    @State var passwordConfirmation = ""
    @State private var isWelcomePresented = false
    @EnvironmentObject var authManager: AuthManager
    var buttonDisabled: Bool {
        return (passwordConfirmation == "" || password != passwordConfirmation)
    }
    
    var body: some View {
        VStack() {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Welcome!")
                        .font(.title)
                        .bold()
                    
                    Text("Please complete the information below to finish creating an account.")
                    
                    VStack(alignment: .center) {
                        //First name
                        EntryField(entryTitle: "First Name", text: $firstName)
                        //Surname
                        EntryField(entryTitle: "Surname", text: $surname)
                        //Username
                        EntryField(entryTitle: "Choose a username", text: $username)
                        //email
                        EntryField(entryTitle: "Email", text: $email, info: true, infoMessage: "Your email will only be used for login \n and password recovery")
                        //password
                        EntryField(entryTitle: "Password", text: $password, info: true, isSecure: true, infoMessage: "Password must be at least 6 digits")
                        //confim password
                        EntryField(entryTitle: "Confirm Password", text: $passwordConfirmation, isSecure: true)
                        
                        
                        //password message
                        if passwordConfirmation != "" {
                            if password == passwordConfirmation {
                                Text("Passwords match")
                                    .foregroundColor(Colors.earthblue)
                            } else {
                                Text("passwords do not match")
                                    .foregroundColor(Colors.lightRed)
                            }
                        }
                        
                        VStack {
                            //login button
                            Button {
                                Task {
                                    try await authManager.createAccount(withEmail: email, password: password, firstName: firstName, surname: surname, username: username)
                                }
                            } label: {
                                NextButton(title: "Create Account")
                                    .padding()
                                    .opacity(buttonDisabled ? 0.5 : 1)
                            }
                            .disabled(buttonDisabled)
                            
                            //error message
                            if let accountStatus = authManager.createAccountStatus {
                                Text(accountStatus)
                                    .foregroundColor(Colors.lightRed)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                
                
                NavigationLink {
                    SignIn()
                } label: {
                    AlternateOption(text: "Back to Sign In", color: Colors.tan)
                        .padding(.bottom, 20)
                }.navigationBarBackButtonHidden()
            }
            .padding()
    
        }
    }}

#Preview {
    Onboarding()
        .environmentObject(AuthManager())
}
