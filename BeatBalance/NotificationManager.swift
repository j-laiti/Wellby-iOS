//
//  NotificationManager.swift
//  BeatBalance
//
//  Created by Justin Laiti on 3/2/24.
//

import Foundation

class NotificationManager {
    static let shared = NotificationManager()
    
    func scheduleNotification(at date: Date) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
    }
}
