//
//  TermsAndConditions.swift
//  BeatBalance
//
//  Created by Justin Laiti on 3/8/24.
//

import SwiftUI

struct TermsAndConditions: View {
    @Binding var accepted: Bool
    
    var body: some View {

        ZStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Terms and Conditions")
                        .font(.title)
                        .padding(.bottom, 2)
                    
                    Group {
                        Text("Introduction")
                            .font(.headline)
                        Text("Welcome to Wellby: Your Well-being Buddy. The app is designed to provide high school students with lifestyle resources, access to health coaches, and tools such as breath pacers for enhancing their well-being.")
                            .padding(.bottom, 2)
                        
                        Text("1. Acceptance of Terms")
                            .font(.headline)
                        Text("You must agree to these Terms before using Wellby. If you are under the age of 18, you must have your parent or guardian read and agree to these Terms on your behalf.")
                            .padding(.bottom, 2)
                        
                    }
                    .padding(.bottom, 1)
                    
                    Group {
                        Text("2. Use of the App")
                            .font(.headline)
                        Text("The app is intended for educational and informational purposes only. You may not use the app for any illegal or unauthorized purpose.")
                            .padding(.bottom, 2)
                        
                        Text("3. User-Generated Content")
                            .font(.headline)
                        Text("You may send messages provided that the content complies with our content guidelines. You agree not to send objectionable content, such as offensive, threatening, or sexually explicit material. We reserve the right to remove any content that violates these Terms.")
                            .padding(.bottom, 2)
                        
                        Text("4. Chat Features")
                            .font(.headline)
                        Text("The chat feature allows you to communicate with health coaches. Be respectful and professional in your interactions. Do not share personal information within chat sessions. Users can report or block abusive users through the app’s reporting mechanisms.")
                            .padding(.bottom, 2)
                        
                        Text("5. Intellectual Property")
                            .font(.headline)
                        Text("All content provided by the app, including resources and tools, is owned by us or our licensors and is protected by copyright and other intellectual property laws. You may not reproduce, distribute, or create derivative works from our content without express permission.")
                            .padding(.bottom, 2)
                        
                        Text("6. Privacy")
                            .font(.headline)
                        Text("Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and share your information.")
                            .padding(.bottom, 2)
                    }
                    .padding(.bottom, 1)
                    
                    Group {
                        Text("7. Disclaimers and Limitations of Liability")
                            .font(.headline)
                        Text("The app is provided on an “as is” basis. We do not guarantee its accuracy, completeness, or usefulness. We are not liable for any damages or loss resulting from your use of the app.")
                            .padding(.bottom, 2)
                        
                        Text("8. Changes to Terms")
                            .font(.headline)
                        Text("We reserve the right to modify these Terms at any time. Your continued use of the app following any changes indicates your acceptance of the new Terms.")
                            .padding(.bottom, 2)
                        
                        Text("9. Governing Law")
                            .font(.headline)
                        Text("These Terms are governed by the laws of Ireland. Any disputes related to these Terms will be subject to the jurisdiction of Irish courts.")
                            .padding(.bottom, 2)
                        
                        Text("Contact Us")
                            .font(.headline)
                        Text("If you have any questions about these Terms, please contact us at justinlaiti22@rcsi.ie.")
                            .padding(.bottom, 2)
                    }
                    .padding(.bottom, 1)
                    
                }
                .padding()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            VStack {
                Spacer()
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "TermsAccepted")
                    accepted = false
                }) {
                    Text("Accept")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
                .padding()
            }

        }.navigationBarTitle("Terms and Conditions", displayMode: .inline)
    }
}
