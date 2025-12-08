//
//  NotificationRequest.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/28/24.
//

import SwiftUI

struct NotificationRequest: View {
    @StateObject var notificationManager = NotificationManager()
    
    var body: some View {
        VStack {
            Button("request notification") {
                Task {
                    await notificationManager.request()
                }
            }
            .buttonStyle(.bordered)
            .disabled(notificationManager.hasPermission)
            .task {
                await notificationManager.getAuthStatus()
            }
        }
    }
}

#Preview {
    NotificationRequest()
}
