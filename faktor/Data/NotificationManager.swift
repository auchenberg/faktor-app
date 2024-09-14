//
//  NotificationManager.swift
//  Faktor
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation
import ServiceManagement
import Combine
import SwiftUI
import Defaults
import UserNotifications
import OSLog

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
            
            Logger.core.info("NotificationManager.messageChanged")
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
        Logger.core.info("Show notification to the user. \(message.0.guid)")
                
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
                Logger.core.error("Error showing notification: \(error.localizedDescription)")
            }
        }
    }
        
    // Handle notification interactions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let messageID = userInfo["messageID"] as? String {
            if let message = messageManager.messages.first(where: { $0.0.guid == messageID }) {
                Logger.core.info("User tapped on notification with message ID: \(messageID)")
                messageManager.copyOTPToClipboard(message: message)
            }
        }
        completionHandler()
    }
}
