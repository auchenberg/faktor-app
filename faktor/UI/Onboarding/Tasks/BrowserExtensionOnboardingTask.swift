//
//  DiskAccessOnboardingItem.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import Foundation
import SwiftUI
import Defaults
import OSLog

struct BrowserExtensionOnboardingTask: View {
    @ObservedObject var appStateManager: AppStateManager

    var body: some View {
        OnboardingItemLayout(
            title: "Install browser extension",
            description: "Faktor uses a browser extension to provide the autocomplete experience"
        ) {
            Image("Xcode")
                .resizable()
                .interpolation(.high)
        } actionView: {
            if !isComplete {
                Button("Install") {
                    self.appStateManager.installBrowserExtension()
                }.buttonStyle(.borderedProminent)
            }
        } content: {
            OnboardingItemStatusIcon(state: isComplete ? .complete : .warning) {
                OnboardingPopoverContent(title: "Needs Setup") {
                    Text("Faktor requires disk access to your library folder to search for new 2fa codes")
                        .lineLimit(2, reservesSpace: true)
                }
            }
        }
    }

    private var isComplete: Bool {
        
        do {
            // Check if Chrome is installed
            let chromeURL = URL(fileURLWithPath: "/Applications/Google Chrome.app")
            guard FileManager.default.fileExists(atPath: chromeURL.path) else {
                return false
            }
        
            // Chrome extension ID for Faktor (replace with actual ID)
            let extensionID = "lnbhbpdjedbjplopnkkimjenlhneekoc"
            
            // Path to Chrome extensions directory
            guard let bookmarkData =  Defaults[.libraryFolderBookmark]  else {
                Logger.core.error("No bookmark data found")
                return false
            }
            
            var bookmarkDataIsStale = false
            
            var extensionsPath = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale)
            
            if bookmarkDataIsStale {
                Logger.core.error("Bookmark data is stale")
            }
            
            if extensionsPath.startAccessingSecurityScopedResource() {
                // Build path for databsse
                extensionsPath.appendPathComponent("/Application Support/Google/Chrome/Default/Extensions")
                extensionsPath.appendPathComponent(extensionID)
                
                // Check if the extension directory exists
                let status = FileManager.default.fileExists(atPath: extensionsPath.path)
                return status
            }
        } catch {
            Logger.core.error("Error resolving bookmark: \(error)")
            return false
        }
        return false
    }
}
