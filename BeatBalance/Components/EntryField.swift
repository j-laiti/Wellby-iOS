//
//  EntryField.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI

struct EntryField: View {
    var entryTitle: String
    @Binding var text: String
    var info = false
    var isSecure = false
    @State var presentInfo = false
    var infoMessage = ""
    
    var body: some View {
        VStack {
            HStack {
                Text(entryTitle)
                Spacer()
            }
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.gray), lineWidth: 1)
                    .frame(height: 40)
                
                if isSecure {
                    SecureField("Enter text here", text: $text)
                        .padding(.horizontal, 8)
                        .textInputAutocapitalization(.never)
                } else {
                    TextField("Enter text here", text: $text)
                        .padding(.horizontal, 8)
                        .textInputAutocapitalization(.never)
                }
                
                HStack {
                    Spacer()
                    
                    if info {
                        //logic here to decide wether or not to show a button with a specified message
                        Button {
                            presentInfo.toggle()
                        } label: {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.gray)
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }
        }
        .overlay(
            Text(infoMessage)
                .font(.callout)
                .foregroundStyle(.black)
                .padding(10)
                .background(.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .opacity(presentInfo ? 1 : 0)
                .offset(x: presentInfo ? 30 : 0,
                        y: presentInfo ? -28 : 0)
                .onTapGesture {
                    // Optionally, you can close the popup when tapped
                    self.presentInfo.toggle()
                }
        )
        .frame(maxWidth: 300)
        
    }
}

#Preview {
    EntryField(entryTitle: "Username", text: .constant(""))
}
