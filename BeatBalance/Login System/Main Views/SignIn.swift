//
//  SignIn.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI

struct SignIn: View {
    @State var email = ""
    @State var password = ""
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        
        NavigationStack {
            VStack(alignment: .center) {
                
                Spacer()
                
                Image("CPHS")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Sign In")
                        .font(.title)
                        .bold()
                    
                    //username field
                    EntryField(entryTitle: "Email", text: $email)
                    //password field
                    EntryField(entryTitle: "Password", text: $password, isSecure: true)
                    
                    //error message
                    if let loginStatus = authManager.loginStatus {
                        Text(loginStatus)
                            .foregroundColor(Colors.lightRed)
                    }
                    
                    //login button
                    Button {
                        Task {
                            try await authManager.signIn(withEmail: email, password: password)
                        }
                        //set the current user
                    } label: {
                        NextButton(title: "Sign In")
                            .padding(.top)
                    }

                    NavigationLink {
                        ResetPassword()
                    } label: {
                        //forgot password button
                        AlternateOption(text: "Forgot Password?", color: Colors.tan)
                    }.navigationBarBackButtonHidden()
                    
                }
                .padding()
                
                Spacer()
                
                NavigationLink {
                    CreateAccount()
                } label: {
                    AlternateOption(text: "Dont have an account? Create one here.", color: Colors.earthblue)
                        .padding()
                }
            }
        }
    }}

#Preview {
    SignIn()
        .environmentObject(AuthManager())
}
