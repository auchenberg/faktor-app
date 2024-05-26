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

class authoApp: App {
    @Default(.settingShowNotifications) var showNotifications
    @Published private var mostRecentMessages: [MessageWithParsedOTP] = []
    var cancellable: Set<AnyCancellable> = [];
    var messageManager: MessageManager?
    var DEFAULT_CONFIG = OTPParserConfiguration(servicePatterns: OTPParserConstants.servicePatterns, knownServices: OTPParserConstants.knownServices, customPatterns: [])
    
    func startListeningForMesssages() {
        
        messageManager?.$messages.sink { [weak self] messages in
            guard let weakSelf = self else { return }
            let newestMessage = messages.last;
            
            if newestMessage != nil && weakSelf.showNotifications {
                weakSelf.showNotificationForMessage(newestMessage!)
            }
            
            // Update most recent messsages
            weakSelf.mostRecentMessages = messages.suffix(3)
        }.store(in: &cancellable)
        
        messageManager?.startListening()
    }

    
    func showNotificationForMessage(_ message: MessageWithParsedOTP) {
        print("showNotificationForMessage")
    }
    
    required init() {
        
        let otpParser = AuthoOTPParser(withConfig: DEFAULT_CONFIG)
        messageManager = MessageManager(withOTPParser: otpParser)
        
        if (AppStateManager.shared.hasRequiredPermissions()) {
            print("Permissions good")
            startListeningForMesssages()
        } else {
            print("Permissions missing")
        }
    }
    
    
    var body: some Scene {
        
        MenuBarExtra("Autho", systemImage: "lock.rectangle") {
            AppMenu(recentMessages: mostRecentMessages)
        }
    
    }
}
