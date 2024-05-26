//
//  authoApp.swift
//  autho
//
//  Created by Kenneth Auchenberg on 5/24/24.
//

import SwiftUI
import SwiftData
import Defaults
import Combine

extension Defaults.Keys {
    static let settingShowNotifications = Key<Bool>("showNotifications", default: true)
    static let settingsEnableBrowserIntegration = Key<Bool>("enableBrowserIntegration", default: true)
}

@main

struct authoApp: App {
    @Default(.settingShowNotifications) var settingShowNotifications
    var messageManager = MessageManager()
        
    init() {
                
        if (AppStateManager.shared.hasRequiredPermissions()) {
            print("Permissions good")
            messageManager.startListening()
        } else {
            print("Permissions missing")
            print("TODO: Show onboarding view")
        }
    }
    
    func showNotification(message: MessageWithParsedOTP) {
        print("Show notifiction")
    }
    
    var body: some Scene {
        
        MenuBarExtra("Autho", systemImage: "lock.rectangle") {
            AppMenu(messageManager: messageManager)
        }
    
    }
}
