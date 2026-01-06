//
//  BrowserExtensionOnboardingTask.swift
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
    @State private var isInstallingNativeMessaging = false
    @State private var nativeMessagingInstalled = false

    var body: some View {
        OnboardingItemLayout(
            title: "Install browser extension in Chrome, Arc, Edge or Brave",
            description: "Faktor uses a browser extension to provide the autocomplete experience"
        ) {
            Image("Xcode")
                .resizable()
                .interpolation(.high)
        } actionView: {
            if !isExtensionInstalled {
                Button("Install") {
                    self.appStateManager.installBrowserExtension()
                    // Also install native messaging manifests for when extension is ready
                    installNativeMessagingManifests()
                }.buttonStyle(.borderedProminent)
            } else if !nativeMessagingInstalled {
                Button(isInstallingNativeMessaging ? "Connecting..." : "Connect") {
                    installNativeMessagingManifests()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isInstallingNativeMessaging)
            }
        } content: {
            OnboardingItemStatusIcon(state: isComplete ? .complete : .warning) {
                OnboardingPopoverContent(title: popoverTitle) {
                    Text(popoverDescription)
                        .lineLimit(2, reservesSpace: true)
                }
            }
        }
        .onAppear {
            checkNativeMessagingStatus()
        }
    }

    // MARK: - Computed Properties

    private var isComplete: Bool {
        isExtensionInstalled && nativeMessagingInstalled
    }

    private var popoverTitle: LocalizedStringKey {
        if isExtensionInstalled && nativeMessagingInstalled {
            return "Connected"
        } else if isExtensionInstalled {
            return "Extension Installed"
        } else {
            return "Needs Setup"
        }
    }

    private var popoverDescription: LocalizedStringKey {
        if isExtensionInstalled && nativeMessagingInstalled {
            return "Browser extension is installed and connected to Faktor"
        } else if isExtensionInstalled {
            return "Click Connect to allow your browser extension to communicate with Faktor"
        } else {
            return "Faktor uses a browser extension to provide the autocomplete experience"
        }
    }

    // MARK: - Native Messaging

    private func installNativeMessagingManifests() {
        isInstallingNativeMessaging = true
        Logger.core.info("BrowserExtensionOnboardingTask: Installing native messaging manifests")

        DispatchQueue.global(qos: .userInitiated).async {
            let results = Self.installManifestsForAllBrowsers()

            DispatchQueue.main.async {
                isInstallingNativeMessaging = false
                let successful = results.filter { $0.value }.count
                Logger.core.info("BrowserExtensionOnboardingTask: Installed \(successful)/\(results.count) manifests")

                if successful > 0 {
                    nativeMessagingInstalled = true
                    Defaults[.nativeMessagingInstalled] = true
                }
            }
        }
    }

    private func checkNativeMessagingStatus() {
        nativeMessagingInstalled = Self.isNativeMessagingInstalled()
    }

    // MARK: - Extension Check

    private var isExtensionInstalled: Bool {
        let browsers: [String: String] = [
            "Google Chrome": "/Applications/Google Chrome.app",
            "Arc": "/Applications/Arc.app",
            "Brave": "/Applications/Brave Browser.app",
            "Microsoft Edge": "/Applications/Microsoft Edge.app"
        ]

        let installedBrowsers = browsers.filter { FileManager.default.fileExists(atPath: $0.value) }

        guard !installedBrowsers.isEmpty else {
            return false
        }

        let extensionID = "afhmgkpdmifnmflcaegmjcaaehfklepp"
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let libraryPath = homeDirectory.appending(path: "/Library")

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

        return false
    }

    // MARK: - Static Native Messaging Helpers

    private static let hostName = "com.faktor.nativehost"
    private static let extensionId = "afhmgkpdmifnmflcaegmjcaaehfklepp"

    private static func isNativeMessagingInstalled() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let manifestPaths = [
            "\(home)/Library/Application Support/Google/Chrome/NativeMessagingHosts/\(hostName).json",
            "\(home)/Library/Application Support/Arc/User Data/NativeMessagingHosts/\(hostName).json",
            "\(home)/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/\(hostName).json",
            "\(home)/Library/Application Support/Microsoft Edge/NativeMessagingHosts/\(hostName).json"
        ]

        return manifestPaths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private static func installManifestsForAllBrowsers() -> [String: Bool] {
        var results: [String: Bool] = [:]

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let browsers: [(name: String, path: String)] = [
            ("Chrome", "\(home)/Library/Application Support/Google/Chrome/NativeMessagingHosts"),
            ("Arc", "\(home)/Library/Application Support/Arc/User Data/NativeMessagingHosts"),
            ("Brave", "\(home)/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"),
            ("Edge", "\(home)/Library/Application Support/Microsoft Edge/NativeMessagingHosts")
        ]

        guard let hostPath = getNativeHostPath() else {
            Logger.core.error("BrowserExtensionOnboardingTask: Native host not found")
            return results
        }

        let manifest: [String: Any] = [
            "name": hostName,
            "description": "Faktor OTP Manager - Native Messaging Host",
            "path": hostPath,
            "type": "stdio",
            "allowed_origins": [
                "chrome-extension://\(extensionId)/"
            ]
        ]

        for browser in browsers {
            do {
                try FileManager.default.createDirectory(atPath: browser.path, withIntermediateDirectories: true)

                let manifestPath = "\(browser.path)/\(hostName).json"
                let jsonData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
                try jsonData.write(to: URL(fileURLWithPath: manifestPath))

                Logger.core.info("BrowserExtensionOnboardingTask: Installed manifest for \(browser.name)")
                results[browser.name] = true
            } catch {
                Logger.core.error("BrowserExtensionOnboardingTask: Failed to install for \(browser.name): \(error.localizedDescription)")
                results[browser.name] = false
            }
        }

        return results
    }

    private static func getNativeHostPath() -> String? {
        if let bundlePath = Bundle.main.bundlePath as String? {
            let hostPath = "\(bundlePath)/Contents/MacOS/FaktorNativeHost"
            if FileManager.default.fileExists(atPath: hostPath) {
                return hostPath
            }
        }

        if let execPath = Bundle.main.executablePath {
            let buildDir = (execPath as NSString).deletingLastPathComponent
            let devHostPath = "\(buildDir)/FaktorNativeHost"
            if FileManager.default.fileExists(atPath: devHostPath) {
                return devHostPath
            }
        }

        return "/Applications/Faktor.app/Contents/MacOS/FaktorNativeHost"
    }
}
