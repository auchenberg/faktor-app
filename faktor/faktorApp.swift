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
    
    let logger = Logger(label: "com.auchenberg.faktor")
    
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
struct faktorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            AppMenu(messageManager: appDelegate.messageManager,
                    appStateManager: appDelegate.appStateManager)
        } label: {
            let image: NSImage = {
                let ratio = $0.size.height / $0.size.width
                $0.size.height = 14
                $0.size.width = 14 / ratio
                return $0
            }(NSImage(named: "menuIcon")!)

            Image(nsImage: image)
        }
    }
}
