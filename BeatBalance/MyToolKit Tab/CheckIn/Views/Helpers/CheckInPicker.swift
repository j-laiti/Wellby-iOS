//
//  CheckInPicker.swift
//  BeatBalance
//
//  Created by Justin Laiti on 2/26/24.
//

import SwiftUI

struct CheckInPicker: View {
    @Binding var selection: Int
    var options: [String]
    var title: String
    
    var body: some View {
        
        VStack(alignment: .center) {
            Picker("Mood", selection: $selection) {
                ForEach(options.indices, id: \.self) { index in
                    Text(options[index])
                        .tag(index)
                }
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(5)
        .accentColor(.black)
            
    }
}
