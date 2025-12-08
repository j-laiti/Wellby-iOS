//
//  TaskCircle.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/31/24.
//

import SwiftUI

struct TaskCircle: View {
    @EnvironmentObject var settings: UserSettings
    let ratioOfCompletedTasks: Double?
    
    var body: some View {
        ZStack {
            if let ratio = ratioOfCompletedTasks {
                Circle()
                    .stroke(lineWidth: 5)
                    .foregroundStyle(.black)
                    .opacity(0.3)
                
                Circle()
                    .trim(from: 0, to: ratio)
                    .stroke(lineWidth: 5)
                    .foregroundStyle(settings.primaryColor)
                    .rotationEffect(.degrees(-90))
            } else {
                Circle()
                    .stroke(lineWidth: 5)
                    .foregroundStyle(.clear)
            }
        }
    }
}
