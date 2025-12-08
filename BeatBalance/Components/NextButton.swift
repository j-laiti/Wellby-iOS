//
//  NextButton.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI

struct NextButton: View {
    var title: String
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(Colors.earthblue)
                .frame(maxWidth: 300, minHeight: 40, maxHeight: 40)
            
            Text(title)
                .foregroundStyle(.white)
                .bold()
            
        }
    }
}

#Preview {
    NextButton(title: "Sign In")
}
