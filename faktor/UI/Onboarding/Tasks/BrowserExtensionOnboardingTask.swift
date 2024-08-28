//
//  DiskAccessOnboardingItem.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import Foundation
import SwiftUI
import Defaults

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
    // Check if Chrome is installed
    let chromeURL = URL(fileURLWithPath: "/Applications/Google Chrome.app")
    guard FileManager.default.fileExists(atPath: chromeURL.path) else {
        return false
    }
    
    // Chrome extension ID for Faktor
    let extensionID = "lnbhbpdjedbjplopnkkimjenlhneekoc"
    
    var bookmarkDataIsStale = false
    guard let bookmarkData = Defaults[.libraryFolderBookmark],
          let extensionsPath = try? URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, 
                                        relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale) else {
        return false
    }
    
    let fullPath = extensionsPath
        .appendingPathComponent("Application Support/Google/Chrome/Default/Extensions")
        .appendingPathComponent(extensionID)
    
    return FileManager.default.fileExists(atPath: fullPath.path)
}
}
