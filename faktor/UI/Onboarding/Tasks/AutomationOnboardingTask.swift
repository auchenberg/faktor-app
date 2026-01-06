//
//  AutomationOnboardingTask.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 1/6/26.
//

import Foundation
import SwiftUI
import OSLog

struct AutomationOnboardingTask: View {
    @ObservedObject var appStateManager: AppStateManager
    @State private var hasAutomationPermission: Bool = false
    @State private var isCheckingPermission: Bool = false

    var body: some View {
        OnboardingItemLayout(
            title: "Automation access to Messages",
            description: "Faktor uses automation to mark verification codes as read after autofill"
        ) {
            Image("Xcode")
                .resizable()
                .interpolation(.high)
        } actionView: {
            if !hasAutomationPermission {
                Button(isCheckingPermission ? "Checking..." : "Grant Access") {
                    requestAutomationPermission()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCheckingPermission)
            }
        } content: {
            OnboardingItemStatusIcon(state: hasAutomationPermission ? .complete : .warning) {
                OnboardingPopoverContent(title: hasAutomationPermission ? "Enabled" : "Needs Setup") {
                    Text(hasAutomationPermission
                         ? "Faktor can mark messages as read after autofill"
                         : "Grant access to allow Faktor to mark codes as read")
                        .lineLimit(2, reservesSpace: true)
                }
            }
        }
        .onAppear {
            checkAutomationPermission()
        }
    }

    // MARK: - Permission Check

    private func checkAutomationPermission() {
        hasAutomationPermission = Self.isAutomationPermissionGranted()
    }

    private func requestAutomationPermission() {
        isCheckingPermission = true
        Logger.core.info("AutomationOnboardingTask: Requesting automation permission")

        DispatchQueue.global(qos: .userInitiated).async {
            // This will trigger the permission prompt if not yet granted
            let granted = Self.triggerAutomationPermissionRequest()

            DispatchQueue.main.async {
                isCheckingPermission = false
                hasAutomationPermission = granted

                if !granted {
                    // Open System Settings to Automation pane
                    Self.openAutomationSettings()
                }
            }
        }
    }

    // MARK: - Static Helpers

    /// Check if automation permission for Messages is granted by trying to access it
    static func isAutomationPermissionGranted() -> Bool {
        // Try to access Messages - if we get -1743, permission is not granted
        let script = """
        tell application "Messages"
            return name
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)

            if let error = error {
                if let errorNumber = error[NSAppleScript.errorNumber] as? Int {
                    Logger.core.info("AutomationOnboardingTask: Permission check error \(errorNumber)")
                    // -1743 = not authorized
                    // -1728 = can't get application (Messages not running, but that's OK)
                    if errorNumber == -1743 {
                        return false
                    }
                }
                // Other errors might mean Messages isn't running, which is fine
                // If we can at least try to talk to it without -1743, permission is likely granted
                return true
            }

            Logger.core.info("AutomationOnboardingTask: Permission check succeeded - \(result.stringValue ?? "nil")")
            return true
        }

        return false
    }

    /// Trigger a simple AppleScript to Messages to prompt for permission
    static func triggerAutomationPermissionRequest() -> Bool {
        // This will trigger the macOS permission prompt if not yet decided
        let script = """
        tell application "Messages"
            return name
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)

            if let error = error {
                Logger.core.warning("AutomationOnboardingTask: AppleScript error - \(error)")

                if let errorNumber = error[NSAppleScript.errorNumber] as? Int,
                   errorNumber == -1743 {
                    // Not authorized - user denied or needs to grant in settings
                    return false
                }
                // Other errors (like Messages not running) are OK
                return true
            }

            Logger.core.info("AutomationOnboardingTask: Permission granted - \(result.stringValue ?? "nil")")
            return true
        }

        return false
    }

    /// Open System Settings to Automation preferences
    static func openAutomationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
            NSWorkspace.shared.open(url)
        }
    }
}
