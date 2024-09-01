import SwiftUI
import SwiftData
import Defaults
import Combine
import PostHog
import LaunchAtLogin
import OSLog

extension Defaults.Keys {
    static let settingShowNotifications = Key<Bool>("showNotifications", default: true)
    static let settingsEnableBrowserIntegration = Key<Bool>("enableBrowserIntegration", default: true)
    static let settingsShowInDock = Key<Bool>("showInDock", default: false)
    static let libraryFolderBookmark = Key<Data?>("libraryFolderBookmark")
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @Default(.settingShowNotifications) var settingShowNotifications
    @Default(.settingsEnableBrowserIntegration) var settingsEnableBrowserIntegration
    @Default(.settingsShowInDock) var settingsShowIndock
    var messageManager = MessageManager()
    var appStateManager = AppStateManager()
    var notificationManager: NotificationManager
    var browserManager: BrowserManager
    var cancellables = Set<AnyCancellable>()
            
    override init() {
        notificationManager = NotificationManager(messageManager: messageManager)
        browserManager = BrowserManager(messageManager: messageManager)
        super.init()
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        appStateManager.updateDockIconVisibility(isVisible: settingsShowIndock)
     }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Analytics
        let POSTHOG_API_KEY = "phc_zlgdjtWBUz7s2P7Hf3OzMkA39WJ4iZWN5bVaoao0sqg"
        let POSTHOG_HOST = "https://us.i.posthog.com"
        
        let config = PostHogConfig(apiKey: POSTHOG_API_KEY, host: POSTHOG_HOST)
        PostHogSDK.shared.setup(config)
        PostHogSDK.shared.capture("faktor.init")
        
        // Permissions
        appStateManager.$hasAllRequiredPermissions
            .removeDuplicates()
            .sink { hasPermissions in
                Logger.core.info("permission.monitor: \(hasPermissions)")
                if hasPermissions {
                    
                    // Let's go!
                    Logger.core.info("permissions.granted.")
                    self.messageManager.startListening()
                    self.browserManager.startServer()
                    
                    // Set up observer for settings changes
                    Task {
                        for await value in Defaults.updates(.settingsShowInDock) {
                            Logger.core.info("updateDockIconVisibility.update")
                            self.appStateManager.updateDockIconVisibility(isVisible: value)
                        }
                    }
                    
                } else {
                    Logger.core.info("permissions.missing.")
                    self.appStateManager.startOnboarding()
                }
            }
            .store(in: &cancellables)
        
        if !appStateManager.isDevelopmentMode() {
            // Configure the application to launch at login.
            if !LaunchAtLogin.isEnabled {
                LaunchAtLogin.isEnabled = true
            }
        }
    }

}

@main
struct faktorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.appStateManager)
        }
        MenuBarExtra {
            AppMenu(messageManager: appDelegate.messageManager,
                    appStateManager: appDelegate.appStateManager,
                    browserManager: appDelegate.browserManager)
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
