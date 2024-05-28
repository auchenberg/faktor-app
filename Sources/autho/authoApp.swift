import SwiftUI
import SwiftData
import Defaults
import Combine
import FullDiskAccess

extension Defaults.Keys {
    static let settingShowNotifications = Key<Bool>("showNotifications", default: true)
    static let settingsEnableBrowserIntegration = Key<Bool>("enableBrowserIntegration", default: true)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @Default(.settingShowNotifications) var settingShowNotifications
    var messageManager = MessageManager()
    var appStateManager = AppStateManager()
    var notificationManager: NotificationManager
    
    override init() {
        notificationManager = NotificationManager(messageManager: messageManager)
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        if (appStateManager.hasRequiredPermissions()) {
            print("Permissions good")
            messageManager.startListening()
        } else {
            print("Permissions missing")
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
