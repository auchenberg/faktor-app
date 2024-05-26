//
//  NotificationManager.swift
//  autho
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation
import ServiceManagement
import Combine
import SwiftUI
import Defaults
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    @Default(.settingShowNotifications) var settingShowNotifications
    @ObservedObject var messageManager: MessageManager
    @Published private var latestMessage: MessageWithParsedOTP?
    private var cancellable: AnyCancellable?
    
    init(messageManager: MessageManager) {
        self.messageManager = messageManager
        super.init()
        UNUserNotificationCenter.current().delegate = self
                
        cancellable = messageManager.$messages.sink { [weak self] messages in
            guard let self = self else {
                return
            }
            
            print("NotificationManager.messageChanged")
            if let newMessage = messages.last {
                if let latestMessage = self.latestMessage {
                    if newMessage != latestMessage {
                        if self.settingShowNotifications {
                            self.showNotification(for: newMessage)
                        }
                    }
                }
            }
            self.latestMessage = messages.last
        }
    }
    
    private func showNotification(for message: MessageWithParsedOTP) {
        print("Show notification to the user. \(message.0.guid)")
        
        let content = UNMutableNotificationContent()
        content.title = "New authentication code received"
        content.body = message.1.code
        content.sound = .default
        content.userInfo = ["messageID": message.0.guid] 

        // Create a trigger to show the notification immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create a request with a unique identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // Add the notification request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }
    
    // Handle notification interactions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let messageID = userInfo["messageID"] as? String {
            if let message = messageManager.messages.first(where: { $0.0.guid == messageID }) {
                print("User tapped on notification with message ID: \(messageID)")
                message.1.copyToClipboard()
            }
        }
        completionHandler()
    }
}
