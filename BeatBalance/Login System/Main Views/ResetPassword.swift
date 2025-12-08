//
//  ResetPassword.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI

struct ResetPassword: View {
    @EnvironmentObject var authManager: AuthManager
    @State var email = ""
    
    var body: some View {
        VStack() {
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Reset Password")
                    .font(.title)
                    .bold()
                
                Text("Enter your email below to get a link to reset your password.")
                
                //username field
                EntryField(entryTitle: "Email", text: $email)
                
                Button {
                    Task {
                        try await authManager.resetPassword(forEmail: email)
                    }
                } label: {
                    //verification button
                    NextButton(title: "Email a reset link")
                }
                
                if let resetStatus = authManager.resetEmailStatus {
                    Text(resetStatus)
                        .foregroundColor(Colors.earthblue)
                }
                
                NavigationLink {
                    SignIn()
                } label: {
                    //forgot password button
                    AlternateOption(text: "Back to Sign In", color: Colors.tan)
                }.navigationBarBackButtonHidden()
            }
            .padding()
            
            Spacer()
            
  
        }
    }}

#Preview {
    ResetPassword()
        .environmentObject(AuthManager())
}
