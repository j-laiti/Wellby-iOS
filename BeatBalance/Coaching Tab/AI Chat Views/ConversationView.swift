//
//  ConversationView.swift
//  BeatBalance
//
//  Created by Justin Laiti on 11/17/24.
//

import SwiftUI

struct ConversationView: View {
    @EnvironmentObject var aiMessagesManager: AiMessagesManager
    @State private var textEditorHeight: CGFloat = 20

    var body: some View {
        VStack {
            
            HStack(alignment: .center, spacing: 10) {
                Spacer()
                Image("chatIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 50)
                Text("Wellby AI")
                    .font(.title3)
                    .bold()
                Spacer()
            }

            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(aiMessagesManager.aiMessages) { message in
                        MessageBlock(message: message)
                    }
                    if aiMessagesManager.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                        .padding()
                        .id("LoadingIndicator")
                    }
                }
                .onAppear {
                    if let lastMessage = aiMessagesManager.aiMessages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
                .onReceive(aiMessagesManager.$aiMessages) { _ in
                    DispatchQueue.main.async {
                        withAnimation {
                            if let lastMessage = aiMessagesManager.aiMessages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .onReceive(aiMessagesManager.$isLoading) { isLoading in
                    print("isLoading changed to: \(isLoading)")
                    DispatchQueue.main.async {
                        withAnimation {
                            if isLoading {
                                print("Scrolling to LoadingIndicator")
                                proxy.scrollTo("LoadingIndicator", anchor: .bottom)
                            }
                        }
                    }
                }
                .onDisappear {
                    aiMessagesManager.resetStates()
                }


            }
            MessageEntryBlock()
                .environmentObject(aiMessagesManager)
        }
    }
}
