//
//  AiChatQuestions.swift
//  BeatBalance
//
//  Created by Justin Laiti on 11/17/24.
//

import SwiftUI

struct AiChatInfo: View {
    @EnvironmentObject var userManager: AuthManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    Text("What you can discuss:")
                        .font(.title2)
                        .bold()
                    Text("""
                    - Stress management
                    - Sleep hygiene
                    - Digital well-being
                    - Healthy eating
                    - Maintaining healthy relationships
                    - Alcohol and tobacco use management
                    - Time management
                    """)
                }
                
                Group {
                    Text("Is this a therapeutic or medical service?")
                        .font(.title2)
                        .bold()
                        .padding(.top, 10)
                    Text("""
                    No, this chat is not a therapeutic or medical service. If you need professional support, please talk to someone you trust or consult a professional. 
                    See the 'Further Support' section for links to free resources.
                    """)
                }
                
                Group {
                    Text("Are my messages confidential?")
                        .font(.title2)
                        .bold()
                        .padding(.top, 10)
                    Text("""
                    Conversations are not saved or monitored by the RCSI research team, but data is processed through OpenAI. Only the most recent 20 messages are saved for you to view.
                    """)
                }
                
                Group {
                    Text("What happens if I mention safety concerns?")
                        .font(.title2)
                        .bold()
                        .padding(.top, 10)
                    Text("""
                    If you mention something that suggests harm to yourself or others, the message may be flagged for review. Flagged messages could be shared with your school to ensure your safety and well-being.
                    """)
                    Text("All non-flagged messages remain confidential and are not saved by RCSI.")
                }
            }
            .padding()
        }
        .navigationTitle("AI Chat Info")
        .onAppear {
            userManager.viewDidAppear(screen: "AI chat info")
        }
    }
}
