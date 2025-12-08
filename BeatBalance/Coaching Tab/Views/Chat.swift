//
//  Chat.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/10/24.
//

import SwiftUI

struct Chat: View {
    @EnvironmentObject var userManager: AuthManager
    @ObservedObject var chatManager: ChatManager
    @EnvironmentObject var settings: UserSettings
    @State var textEditorHeight : CGFloat = 20
    
    @State private var showOptions = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            
            HStack(alignment: .center) {
                Spacer()
                
                Image("coach")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                
                VStack {
                    Text("\(userManager.chatUser?.username ?? "")")
                        .font(.title3)
                        .bold()
                    
                    if let school = userManager.chatUser?.school, school != "" {
                        Text("School: \(school)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    self.showOptions = true
                }) {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
                .actionSheet(isPresented: $showOptions) {
                    ActionSheet(
                        title: Text("Options"),
                        buttons: [
                            .default(Text("Flag as Objectionable")) {
                                chatManager.reportObjectionableContent()
                                self.alertTitle = "Flagged"
                                self.alertMessage = "The conversation has been flagged as objectionable and will be reviewed."
                                self.showAlert = true
                            },
                            .destructive(Text("Block User")) {
                                chatManager.blockChatUser()
                                self.alertTitle = "User Blocked"
                                self.alertMessage = "The user has been blocked and you will no longer be able to message them. If this was a mistake, please contact justinlaiti22@rcsi.ie to unblock the user."
                                self.showAlert = true
                            },
                            .cancel()
                        ]
                    )
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
            }
            .padding()

            ScrollViewReader {proxy in
                ScrollView {
                    
                    ForEach(chatManager.messages) { message in
                        VStack {
                            ForEach(detectLinks(in: message.text), id: \.text) { segment in
                                if segment.isLink {
                                    Link(segment.text, destination: URL(string: segment.text)!)
                                        .foregroundColor(.blue)
                                } else {
                                    Text(segment.text)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding(EdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15))
                            .background(message.currentUserID == userManager.currentUser?.id ? settings.primaryColor.opacity(0.7) : Color.gray.opacity(0.3))
                            .cornerRadius(20)
                            .frame(maxWidth: UIScreen.main.bounds.width - 75, alignment: message.currentUserID == userManager.currentUser?.id ? .trailing : .leading)
                        }
                        .frame(maxWidth: UIScreen.main.bounds.width - 32, alignment: message.currentUserID == userManager.currentUser?.id ? .trailing : .leading)
                    }
                }
                .onReceive(chatManager.$lastMessageID) { newID in
                    withAnimation {
                        proxy.scrollTo(newID, anchor: .bottom)
                    }
                }
                .onAppear {
                    chatManager.getMessages()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let lastMessage = chatManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            HStack {
                ZStack(alignment: .leading) {
                    Text(chatManager.message)
                        .font(.system(.body))
                        .foregroundColor(.clear)
                        .padding(14)
                        .background(GeometryReader {
                            Color.clear.preference(key: ViewHeightKey.self,
                                                   value: $0.frame(in: .local).size.height)
                        })
                    
                    TextEditor(text: $chatManager.message)
                        .font(.system(.body))
                        .frame(height: max(40,textEditorHeight))
                        .cornerRadius(10.0)
                        .shadow(radius: 1.0)
                        .shadow(color: Color(.sRGBLinear, white: 1, opacity: 0.6), radius: 1.0, x: 0, y: 0)
                }.onPreferenceChange(ViewHeightKey.self) { textEditorHeight = $0 }
                //some kind of frame added here in dark mode

                Button {
                    chatManager.sendMessage()
                    chatManager.message = ""
                    userManager.clickedOn(feature: "send coach a message")
                } label: {
                    Image(systemName: "paperplane.circle")
                        .font(.title)
                }
            }
            .padding()

        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

func detectLinks(in text: String) -> [(text: String, isLink: Bool)] {
    var result: [(text: String, isLink: Bool)] = []
    let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []

    var lastRangeEnd = text.startIndex
    for match in matches {
        guard let range = Range(match.range, in: text) else { continue }
        let beforeLink = text[lastRangeEnd..<range.lowerBound]
        if !beforeLink.isEmpty {
            result.append((String(beforeLink), false))
        }
        let linkText = text[range]
        result.append((String(linkText), true))
        lastRangeEnd = range.upperBound
    }
    if lastRangeEnd < text.endIndex {
        result.append((String(text[lastRangeEnd...]), false))
    }

    return result
}



