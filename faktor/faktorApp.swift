import SwiftUI
import SwiftData
import Defaults
import Combine
import PostHog
import LaunchAtLogin
import OSLog
import FluidMenuBarExtra
import SettingsAccess

extension Defaults.Keys {
    static let settingShowNotifications = Key<Bool>("showNotifications", default: true)
    static let settingsEnableBrowserIntegration = Key<Bool>("enableBrowserIntegration", default: true)
    static let libraryFolderBookmark = Key<Data?>("libraryFolderBookmark")
    static let nativeMessagingInstalled = Key<Bool>("nativeMessagingInstalled", default: false)
}

@main
struct faktorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.appStateManager)
                .environmentObject(appDelegate.browserManager)
               .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeMainNotification)) { newValue in
                   NSApp.activate(ignoringOtherApps: true)
                   NSApp.setActivationPolicy(.regular)
                   NSApp.windows.first?.orderFrontRegardless()
               }
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    @Default(.settingShowNotifications) var settingShowNotifications
    @Default(.settingsEnableBrowserIntegration) var settingsEnableBrowserIntegration
    var messageManager = MessageManager()
    var appStateManager = AppStateManager()
    var notificationManager: NotificationManager
    var browserManager: BrowserManager
    var cancellables = Set<AnyCancellable>()
    private var menuBarExtra: FluidMenuBarExtra?
    @State var isMenuPresented: Bool = false

    override init() {
        notificationManager = NotificationManager(messageManager: messageManager)
        browserManager = BrowserManager(messageManager: messageManager)
        super.init()
    }
        
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        // Analytics
        let POSTHOG_API_KEY = "phc_zlgdjtWBUz7s2P7Hf3OzMkA39WJ4iZWN5bVaoao0sqg"
        let POSTHOG_HOST = "https://us.i.posthog.com"
        
        let config = PostHogConfig(apiKey: POSTHOG_API_KEY, host: POSTHOG_HOST)
        PostHogSDK.shared.setup(config)
        PostHogSDK.shared.capture("faktor.init")
        
        // Menubar
        menuBarExtra = FluidMenuBarExtra(title: "Faktor",  image: "menu.icon") {
            AppMenu()
                .environmentObject(self.appStateManager)
                .environmentObject(self.browserManager)
                .environmentObject(self.messageManager)
                .openSettingsAccess()
        }

        // Permissions
        appStateManager.$hasAllRequiredPermissions
            .removeDuplicates()
            .sink { hasPermissions in
                Logger.core.info("appDelegate.applicationDidFinishLaunching: permission.monitor: \(hasPermissions)")
               if hasPermissions {
                   // Let's go!
                   self.messageManager.startListening()
                   self.browserManager.startServer()
               } else {
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
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
       // See https://www.hackingwithswift.com/forums/macos/how-to-open-settings-from-menu-bar-app-and-show-app-icon-in-dock/26267
       NSApp.setActivationPolicy(.accessory)
       NSApp.deactivate()
        return false
    }

    // MARK: - URL Scheme Handling

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleURL(url)
        }
    }

    private func handleURL(_ url: URL) {
        Logger.core.info("faktorApp: Received URL: \(url.absoluteString)")

        guard url.scheme == "faktor" else {
            Logger.core.warning("faktorApp: Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }

        let host = url.host ?? ""

        switch host {
        case "activate":
            // Just activate/launch the app - no UI action needed
            // The app is already running if we received this
            Logger.core.info("faktorApp: Activated via URL scheme")

        case "settings":
            // Open settings window
            NSApp.activate(ignoringOtherApps: true)
            if #available(macOS 14.0, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } else if #available(macOS 13.0, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

        default:
            Logger.core.info("faktorApp: Unknown URL host: \(host)")
        }
    }
}
