//
//  CreateAccount.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI

struct CreateAccount: View {
    @State var code = ""
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack() {
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Create Account")
                    .font(.title)
                    .bold()
                
                //username field
                EntryField(entryTitle: "Study Code", text: $code)
                
                //error message
                if let codeStatus = authManager.codeStatus {
                    Text(codeStatus)
                        .foregroundColor(Colors.lightRed)
                }
                
                //verification button
                Button {
                    Task {
                        try await authManager.checkStudyCode(code: code) { codeExists in
                            if codeExists {
                                print("found the code :)")
                            } else {
                                print("didn't find the code :(")
                            }
                        }
                    }
                } label: {
                    NextButton(title: "Verify Study Code")
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
        .ignoresSafeArea()
        .navigationDestination(isPresented: $authManager.codeFound) {
            Onboarding()
        }
    }
}

#Preview {
    CreateAccount()
        .environmentObject(AuthManager())
}
