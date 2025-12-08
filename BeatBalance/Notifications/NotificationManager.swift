//
//  NotificationManager.swift
//  BeatBalance
//
//  Created by Justin Laiti on 1/28/24.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private let notificationsScheduledKey = "notificationsScheduled"
    
    func checkForPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                let options: UNAuthorizationOptions = [.alert, .sound, .badge]
                center.requestAuthorization(options: options) { granted, error in
                    if granted {
                        self.scheduleNotification()
                    }
                    if let error = error {
                        print("Notification Authorization Error: \(error)")
                    }
                }
            case .denied:
                return
            case .authorized:
                self.checkNotifications()
            default:
                return
            }
        }

    }
    
    func checkNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let isScheduled = UserDefaults.standard.bool(forKey: self.notificationsScheduledKey)
            
            // Only schedule new notifications if they haven't been set for this week
            if requests.isEmpty && !isScheduled {
                self.scheduleNotification()
                UserDefaults.standard.set(true, forKey: self.notificationsScheduledKey)
                
                // Reset the flag every week
                self.resetScheduledFlagWeekly()
            }
        }
    }
    
    private func resetScheduledFlagWeekly() {
        // Calculate the time until the end of the week and set a timer to reset the flag
        let now = Date()
        let calendar = Calendar.current
        let endOfWeek = calendar.nextWeekend(startingAfter: now)?.start ?? now
        let timeInterval = endOfWeek.timeIntervalSince(now)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) {
            UserDefaults.standard.set(false, forKey: self.notificationsScheduledKey)
        }
    }

    
    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Check-in time!"
        content.body = "When you can, please take a quick moment to check-in."
        content.sound = UNNotificationSound.default

        for _ in 1...2 { // set notifications twice a week at random times
            var dateComponents = DateComponents()
            dateComponents.weekday = Int.random(in: 2...6)
            dateComponents.hour = Int.random(in: 15...20)
            dateComponents.minute = Int.random(in: 0...59)

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            center.add(request) { (error) in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    
    }
}
