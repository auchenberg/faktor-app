//
//  AppStateManager.swift
//  Faktor
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation
import ServiceManagement
import SwiftUI
import ApplicationServices
import UserNotifications
import UniformTypeIdentifiers
import Defaults
import PostHog
import Logging

class AppStateManager: ObservableObject, Identifiable {
    
    @Published private(set) var hasAllRequiredPermissions: Bool = false
    
    private var onboardingWindow: NSWindow?
            
    init() {
        updatePermissionsStatus()
    }
    
    private func updatePermissionsStatus() {
        hasAllRequiredPermissions = hasRequiredPermissions()
    }
            
    func hasRequiredPermissions() -> Bool {
        let result = hasLibraryAccessPermissions() && hasNotificationPermissions()
        return result
    }

    func hasLibraryAccessPermissions() -> Bool {
        
        if Defaults[.libraryFolderBookmark] == nil {
            return false
        }
        return true;
    }
    
    func hasNotificationPermissions() -> Bool {
        var hasPermission = false
        let semaphore = DispatchSemaphore(value: 0)
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            hasPermission = settings.authorizationStatus == .authorized
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 5)  // Wait for up to 5 seconds
        return hasPermission
    }

    func installBrowserExtension() {
        let chromeExtensionURL = "https://chrome.google.com/webstore/detail/faktor/lnbhbpdjedbjplopnkkimjenlhneekoc"
        
        if let url = URL(string: chromeExtensionURL) {
            NSWorkspace.shared.open(url)
        } else {
            print("Failed to create URL for Chrome Web Store")
        }
    }

    func markOnboardingAsCompleted() {
        closeOnboardingWindow()
        
        self.updateDockIconVisibility(isVisible: false)

        // Update settings
//        logger.info("Onboarding marked as completed")
        PostHogSDK.shared.capture("onboarding_completed")
    }
    
    func startOnboarding() {
        
        print("startOnboarding")
        self.updateDockIconVisibility(isVisible: true)
        
        
        if let existingWindow = onboardingWindow {
            existingWindow.makeKeyAndOrderFront(nil)
        } else {
            let newOnboardingWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 650),
                styleMask: [.titled, .fullSizeContentView, .closable],
                backing: .buffered,
                defer: false
            )
            newOnboardingWindow.center()
            newOnboardingWindow.title = "Welcome to Faktor"
            newOnboardingWindow.contentView = NSHostingView(rootView:
                OnboardingView()
                    .environmentObject(self)
            )
            newOnboardingWindow.makeKeyAndOrderFront(nil)
            newOnboardingWindow.isReleasedWhenClosed = false
            onboardingWindow = newOnboardingWindow
        }
    }

    func closeOnboardingWindow() {
        onboardingWindow?.close()
        onboardingWindow = nil
    }
    
    @MainActor
    func requestNotificationPermission() async -> UNAuthorizationStatus {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            updatePermissionsStatus()
            return .authorized
        } catch {
            print("Error requesting notification permission: \(error.localizedDescription)")
            updatePermissionsStatus()
            return .notDetermined
        }
    }
    
    func requestLibraryFolderAccess() -> Bool {
        var homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        homeDirectory.appendPathComponent("/Library")
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.showsHiddenFiles = true
        openPanel.directoryURL = URL(string: homeDirectory.absoluteString)
        
        if let dbType = UTType(filenameExtension: "db") {
            openPanel.allowedContentTypes = [dbType]
        }
        
        openPanel.message = "Please grant access to the Library folder. It should already be selected for you."
        openPanel.prompt = "Grant Access"
        
        let result = openPanel.runModal()
        
        if result == NSApplication.ModalResponse.OK {
            if let url = openPanel.url {
                do {
                    let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    Defaults[.libraryFolderBookmark] = bookmarkData
                    updatePermissionsStatus()
                    return true
                } catch {
                    print("Failed to create bookmark: \(error)")
                }
            }
        }
        
        updatePermissionsStatus()
        return false
    }
    
    func resetStateAndQuit() {
        Defaults.reset(.libraryFolderBookmark);
        Defaults.reset(.settingShowNotifications);
        Defaults.reset(.settingsShowInDock)
        Defaults.reset(.settingsEnableBrowserIntegration)
        
        NSApplication.shared.terminate(nil)
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
    
    func updateDockIconVisibility(isVisible: Bool = false) {
        NSApp.setActivationPolicy(isVisible ? .regular : .accessory)
    }

}

