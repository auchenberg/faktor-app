import SwiftUI
import SwiftData
import Defaults
import Combine
import PostHog

import Logging

extension Defaults.Keys {
    static let settingShowNotifications = Key<Bool>("showNotifications", default: true)
    static let settingsEnableBrowserIntegration = Key<Bool>("enableBrowserIntegration", default: true)
    static let settingsShowWelcome = Key<Bool>("showWelcome", default: true)
    static let settingsShowInDock = Key<Bool>("showInDock", default: false)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @Default(.settingShowNotifications) var settingShowNotifications
    @Default(.settingsEnableBrowserIntegration) var settingsEnableBrowserIntegration
    @Default(.settingsShowWelcome) var settingsShowWelcome
    @Default(.settingsShowInDock) var settingsShowIndock
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
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        updateDockIconVisibility(isVisible: settingsShowIndock)
        
        // Set up observer for settings changes
        Task {
            for await value in Defaults.updates(.settingsShowInDock) {
                self.updateDockIconVisibility(isVisible: value)
            }
        }

     }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Analytics
        let POSTHOG_API_KEY = "phc_zlgdjtWBUz7s2P7Hf3OzMkA39WJ4iZWN5bVaoao0sqg"
        let POSTHOG_HOST = "https://us.i.posthog.com"
        
        let config = PostHogConfig(apiKey: POSTHOG_API_KEY, host: POSTHOG_HOST)
        PostHogSDK.shared.setup(config)
        PostHogSDK.shared.capture("faktor.init")
        
        // Permissions
        if (appStateManager.hasRequiredPermissions()) {
            logger.info("Permissions good")
            messageManager.startListening()
            browserManager.startServer()
        } else {
            logger.info("Permissions missing")
            appStateManager.requestPermissions()
        }
        
        if(settingsShowWelcome) {
            // Show welcome view
        }
    
    }
    
    // Initial setup of dock icon visibility
    func updateDockIconVisibility(isVisible: Bool = false) {
        print("updateDockIconVisibility", isVisible)
        NSApp.setActivationPolicy(isVisible ? .regular : .accessory)
    }
}

@main
struct faktorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
        MenuBarExtra {
            AppMenu(messageManager: appDelegate.messageManager,
                    appStateManager: appDelegate.appStateManager)
        } label: {
            let image: NSImage = {
                let ratio = $0.size.height / $0.size.width
                $0.size.height = 14
                $0.size.width = 14 / ratio
                $0.isTemplate = true
                return $0
            }(NSImage(named: "menuIcon")!)

            Image(nsImage: image)
        }
    }
}
