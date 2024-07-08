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

class AppStateManager: ObservableObject, Identifiable {
            
    func hasRequiredPermissions() -> Bool {
        if UserDefaults.standard.data(forKey: "messagesLibraryFolder") == nil {
            return false
        }
        return true;
    }
    
    func requestPermissions() {
        
//        requestNotificationPermission()

        let alert = NSAlert()
        alert.messageText =  "Enable disk access for Faktor"
        alert.informativeText =  "Faktor requires disk access to your library folder to search for new 2fa codes"
        alert.icon = AppStateManager.alertIcon()
        alert.addButton(withTitle: "Open settings")
        alert.addButton(withTitle: "Quit")

        let response = alert.runModal()

        switch response {
            case .alertFirstButtonReturn:
                requestLibraryFolderAccess();

            case .alertSecondButtonReturn:
                exit(0)
                
            default:
                return
        }
    }
    
    @MainActor
    func requestNotificationPermission() async -> UNAuthorizationStatus {
        do {
            let settings = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert])
            return .authorized
        } catch {
            print("Error requesting notification permission: \(error.localizedDescription)")
            return .notDetermined
        }
    }
    
    func requestLibraryFolderAccess() -> Bool {
        var homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        homeDirectory.appendPathComponent("/Library/Messages")
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.showsHiddenFiles = true
        openPanel.directoryURL = URL(string: homeDirectory.absoluteString)
        
        if let dbType = UTType(filenameExtension: "db") {
            openPanel.allowedContentTypes = [dbType]
        }
        
        openPanel.message = "Please grant access to the Messages folder. It should already be selected for you."
        
        let result = openPanel.runModal()
        
        if result == NSApplication.ModalResponse.OK {
            if let url = openPanel.url {
                do {
                    let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(bookmarkData, forKey: "messagesLibraryFolder")
                    return true
                } catch {
                    print("Failed to create bookmark: \(error)")
                }
            }
        }
        
        return false
    }
    
    func resetStateAndQuit() {
        
        UserDefaults.standard.removeObject(forKey: "messagesLibraryFolder")
        UserDefaults.standard.removeObject(forKey: "showNotifications")
        UserDefaults.standard.removeObject(forKey: "enableBrowserIntegration")
        UserDefaults.standard.removeObject(forKey: "showWelcome")
        
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
    
    private static func alertIcon() -> NSImage? {
        guard let appIconImage = NSApp.applicationIconImage else {
            return NSImage(named: "NSInfo")
        }

        // Draw the app icon with a badge (privacy icon or info icon if unavailable)
        let appIconInset: CGFloat = 4
        let badgeImage: NSImage?
        let badgeSize: CGSize?
        let badgeDrawingScale: CGFloat

        if #available(macOS 13.0, *), let privacyPrefPaneType = UTType("com.apple.graphic-icon.privacy") {
            let privacyIcon = NSWorkspace.shared.icon(for: privacyPrefPaneType)
            badgeImage = privacyIcon
            badgeSize = privacyIcon.size
            badgeDrawingScale = 1.8
        } else {
            badgeImage = NSImage(named: "NSInfo")
            badgeSize = nil
            badgeDrawingScale = 0.45
        }

        return NSImage(size: appIconImage.size, flipped: false) { drawRect in
            appIconImage.draw(in: drawRect.insetBy(dx: appIconInset, dy: appIconInset))

            // Draw the badge
            if let badgeImage {
                let size = badgeSize ?? drawRect.size
                let badgeRect = NSRect(
                    x: drawRect.size.width - (size.width * badgeDrawingScale),
                    y: 0,
                    width: size.width * badgeDrawingScale,
                    height: size.height * badgeDrawingScale
                )
                badgeImage.draw(in: badgeRect)
            }

            return true
        }
    }
    
}

