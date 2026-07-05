//
//  NotificationManager.swift
//  Lumey
//

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
            
            print("Notifications granted: \(granted)")
        }
    }
    
    func scheduleCalendarEvent(
        id: String,
        title: String,
        body: String,
        fireDate: Date,
        sound: UNNotificationSound = .default
    ) {
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(withIdentifiers: [id])
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        
        let dateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule notification \(id): \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleTimeIntervalEvent(
        id: String,
        title: String,
        body: String,
        secondsFromNow: TimeInterval,
        sound: UNNotificationSound = .default
    ) {
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(withIdentifiers: [id])
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(secondsFromNow, 1),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error {
                print("Failed to schedule notification \(id): \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [id]
        )
    }
    
    func cancelNotifications(ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ids
        )
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
