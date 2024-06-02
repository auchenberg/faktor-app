import SwiftUI
import SwiftData
import Defaults
import Combine
import FullDiskAccess

import Logging

extension Defaults.Keys {
    static let settingShowNotifications = Key<Bool>("showNotifications", default: true)
    static let settingsEnableBrowserIntegration = Key<Bool>("enableBrowserIntegration", default: true)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @Default(.settingShowNotifications) var settingShowNotifications
    @Default(.settingsEnableBrowserIntegration) var settingsEnableBrowserIntegration
    var messageManager = MessageManager()
    var appStateManager = AppStateManager()
    var notificationManager: NotificationManager
    var browserManager: BrowserManager
    
    let logger = Logger(label: "com.auchenberg.autho")
    
    override init() {
        notificationManager = NotificationManager(messageManager: messageManager)
        browserManager = BrowserManager(messageManager: messageManager)
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        if (appStateManager.hasRequiredPermissions()) {
            logger.info("Permissions good")
            messageManager.startListening()
            browserManager.startServer()
        } else {
            logger.info("Permissions missing")
            appStateManager.requestPermissions()
        }
    }
}

@main
struct authoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Autho", systemImage: "lock.rectangle") {
            AppMenu(messageManager: appDelegate.messageManager,
                    appStateManager: appDelegate.appStateManager)
        }
    }
}
