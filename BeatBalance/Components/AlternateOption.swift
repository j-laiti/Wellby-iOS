//
//  AlternateOption.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/9/24.
//

import SwiftUI

struct AlternateOption: View {
    var text: String
    var color: Color
    
    var body: some View {
        Text(text)
            .bold()
            .foregroundColor(color)
    }
}

#Preview {
    AlternateOption(text: "Forgot Password", color: Colors.tan)
}
