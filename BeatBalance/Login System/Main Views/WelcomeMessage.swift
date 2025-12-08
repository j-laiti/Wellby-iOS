//
//  WelcomeMessage.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI

struct WelcomeMessage: View {
    var body: some View {
        VStack {
            Text("Thanks a million for signing up! It's great to have you on board and this project wouldn't be possible without you.")
                .font(.title2)
                .bold()
                .padding(30)
            NextButton(title: "Sign In")
        }
    }
}

#Preview {
    WelcomeMessage()
}
