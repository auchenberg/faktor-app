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
import OSLog

class AppStateManager: ObservableObject, Identifiable {
    
    @Published private(set) var hasAllRequiredPermissions: Bool = false
    @Published private(set) var isOnboardingRunning: Bool = false
    
    private var onboardingWindow: NSWindow?
    private var permissionCheckTimer: Timer?
            
    init() {
        Logger.core.info("appStateManager.init")
        updatePermissionsStatus()
    }
    
    private func updatePermissionsStatus() {
        Logger.core.info("appStateManager.updatePermissionsStatus")
        hasAllRequiredPermissions = hasRequiredPermissions()
    }
            
    func hasRequiredPermissions() -> Bool {
        Logger.core.info("appStateManager.hasRequiredPermissions")
        let result = hasLibraryAccessPermissions() && hasNotificationPermissions()
        return result
    }

    func hasLibraryAccessPermissions() -> Bool {
        Logger.core.info("appStateManager.hasLibraryAccessPermissions")
        if Defaults[.libraryFolderBookmark] == nil {
            return false
        }
        return true;
    }
    
    func hasNotificationPermissions() -> Bool {
        Logger.core.info("appStateManager.hasNotificationPermissions")
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
        Logger.core.info("appStateManager.installBrowserExtension")
        let chromeExtensionURL: String = "https://chrome.google.com/webstore/detail/faktor/lnbhbpdjedbjplopnkkimjenlhneekoc"
        
        if let url: URL = URL(string: chromeExtensionURL) {
            NSWorkspace.shared.open(url)
        } else {
            Logger.core.info("appStateManager.installBrowserExtension.error: Failed to open URL for Chrome Web Store")
        }
    }

    func markOnboardingAsCompleted() {
        Logger.core.info("appStateManager.markOnboardingAsCompleted")
        
        self.closeOnboardingWindow()
        self.updateDockIconVisibility(isVisible: false)

        PostHogSDK.shared.capture("onboarding_completed")
    }
    
    func startOnboarding() {
        Logger.core.info("appStateManager.startOnboarding")
        isOnboardingRunning = true

        self.updateDockIconVisibility(isVisible: true)

        startPermissionCheck()
        
        if let existingWindow = onboardingWindow {
            existingWindow.orderFrontRegardless()
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
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
            newOnboardingWindow.orderFrontRegardless()
            
            newOnboardingWindow.isReleasedWhenClosed = false
            // newOnboardingWindow.level = .floating
            onboardingWindow = newOnboardingWindow
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeOnboardingWindow() {
        Logger.core.info("appStateManager.closeOnboardingWindow")
        onboardingWindow?.close()
        onboardingWindow = nil
        isOnboardingRunning = false
        stopPermissionCheck()
    }
    
    @MainActor
    func requestNotificationPermission() async -> UNAuthorizationStatus {
        Logger.core.info("appStateManager.requestNotificationPermission")
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            updatePermissionsStatus()
            return .authorized
        } catch {
            Logger.core.error("appStateManager.requestNotificationPermission.error: \(error.localizedDescription)")
            updatePermissionsStatus()
            return .notDetermined
        }
    }
    
    func requestLibraryFolderAccess() -> Bool {
        Logger.core.info("appStateManager.requestLibraryFolderAccess")
        var homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
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
            if let url: URL = openPanel.url {
                do {
                    let bookmarkData: Data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    Defaults[.libraryFolderBookmark] = bookmarkData
                    updatePermissionsStatus()
                    return true
                } catch {
                    Logger.core.error("appStateManager.requestLibraryFolderAccess.error: \(error)")
                }
            }
        }
        
        updatePermissionsStatus()
        return false
    }
    
    func resetStateAndQuit() {
        Logger.core.info("appStateManager.resetStateAndQuit")
        Defaults.reset(.libraryFolderBookmark);
        Defaults.reset(.settingShowNotifications);
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
        Logger.core.info("appStateManager.updateDockIconVisibility: \(isVisible)")
        NSApp.setActivationPolicy(isVisible ? .regular : .accessory)
    }

    private func startPermissionCheck() {
        Logger.core.info("appStateManager.startPermissionCheck")
        if permissionCheckTimer == nil {
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
                self?.checkPermissions()
            }
        }
    }
    
    private func stopPermissionCheck() {
        Logger.core.info("appStateManager.stopPermissionCheck")
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
    
    private func checkPermissions() {
        Logger.core.info("appStateManager.checkPermissions")
        updatePermissionsStatus()
    }
}

