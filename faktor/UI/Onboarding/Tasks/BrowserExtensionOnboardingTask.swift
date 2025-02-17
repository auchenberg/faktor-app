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
            title: "Install browser extension in Chrome, Arc, Edge or Brave",
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
                    Text("Faktor uses a browser extension to provide the autocomplete experience")
                        .lineLimit(2, reservesSpace: true)
                }
            }
        }
    }

    private var isComplete: Bool {
        do {
            // Check if any supported browser is installed
            let browsers: [String : String] = [
                "Google Chrome": "/Applications/Google Chrome.app",
                "Arc": "/Applications/Arc.app",
                "Brave": "/Applications/Brave Browser.app",
                "Microsoft Edge": "/Applications/Microsoft Edge.app"
            ]
            
            let installedBrowsers: [String : String] = browsers.filter { FileManager.default.fileExists(atPath: $0.value) }
            
            guard !installedBrowsers.isEmpty else {
                return false
            }

            // Chrome extension ID for Faktor (replace with actual ID)
            let extensionID: String = "lnbhbpdjedbjplopnkkimjenlhneekoc"
            
            var homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            let libraryPath: URL = homeDirectory.appending(path: "/Library")
            
            for (browser, _) in installedBrowsers {
                var extensionsPath = libraryPath
                switch browser {
                case "Google Chrome":
                    extensionsPath.appendPathComponent("Application Support/Google/Chrome/Default/Extensions")
                case "Arc":
                    extensionsPath.appendPathComponent("Application Support/Arc/User Data/Default/Extensions")
                case "Brave":
                    extensionsPath.appendPathComponent("Application Support/BraveSoftware/Brave-Browser/Default/Extensions")
                case "Microsoft Edge":
                    extensionsPath.appendPathComponent("Application Support/Microsoft Edge/Default/Extensions")
                default:
                    continue
                }
                
                extensionsPath.appendPathComponent(extensionID)
                
                if FileManager.default.fileExists(atPath: extensionsPath.path) {
                    return true
                }
            }
      
        } catch {
            Logger.core.error("browserExtensionOnboardingTask.error: Error checking for browser extensions: \(error)")
        }
        return false
    }
}
