//
//  AppStateManager.swift
//  autho
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation
import ServiceManagement
import SwiftUI
import ApplicationServices
import FullDiskAccess
import UserNotifications

class AppStateManager: ObservableObject, Identifiable {
            
    func hasRequiredPermissions() -> Bool {
        FullDiskAccess.isGranted
    }
    
    func requestPermissions() {
        requestNotificationPermission();
        
        FullDiskAccess.promptIfNotGranted(
            title: "Enable Full Disk Access for Faktor",
            message: "Faktor requires Full Disk Access to search for new 2fa codes",
            settingsButtonTitle: "Open Settings",
            skipButtonTitle: "Later",
            canBeSuppressed: false,
            icon: nil
        )

    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription),")
            } else if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }
    func isDevelopmentMode() -> Bool {
        #if DEBUG
            return true
        #elseif ADHOC
            return true
        #else
            return false
        #endif
    }
    
}
