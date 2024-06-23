//
//  AppMenu.swift
//  codefill
//
//  Created by Kenneth Auchenberg on 5/23/24.
//

import SwiftUI
import Foundation

import LaunchAtLogin
import Defaults
import PostHog

struct AppMenu: View {
    
    @State private var isLaunchedAtLoginEnabled: Bool = LaunchAtLogin.isEnabled
    @ObservedObject var messageManager: MessageManager
    @ObservedObject var appStateManager: AppStateManager
    @Default(.settingShowNotifications) var showNotifications
    @Default(.settingsEnableBrowserIntegration) var enableBrowserIntegration
    
    func onCodeClicked(message: MessageWithParsedOTP) {
        message.1.copyToClipboard()
        PostHogSDK.shared.capture("faktor.copyToClipboard")
    }
    
    var body: some View {

        if !appStateManager.hasRequiredPermissions() {
            Button("Permissions required. Click here") {
                appStateManager.requestPermissions()
            }
        }
        
        if appStateManager.hasRequiredPermissions() {
            Button("Recent") {
            }.disabled(true)
            
            // List recent messages
            ForEach(messageManager.messages.reversed().prefix(3), id: \.0.guid) { message in
                Button(action: {onCodeClicked(message: message)}, label: {
                    Text(message.1.code + " from " + (message.1.service ?? "unknown"))
                })
            }
        }

        if appStateManager.isDevelopmentMode() {
            
            Divider()
            
            Button("DEBUG: Trigger new code") {
                messageManager.generateRandomMessage()
            }
        }
        
        Divider()
        
        // List preferences
        Menu("Preferences") {
            Toggle(isOn: $showNotifications) {
                 Text("Show Notifications")
             }
             .toggleStyle(.checkbox)
            Toggle(isOn: $enableBrowserIntegration) {
                 Text("Enable browser integration")
             }
             .toggleStyle(.checkbox)
            Toggle(isOn: $isLaunchedAtLoginEnabled) {
                 Text("Open at Login")
             }
             .toggleStyle(.checkbox)
             .onChange(of:isLaunchedAtLoginEnabled) { newState in
                 print("Checkbox state is now: \(newState)")
                 LaunchAtLogin.isEnabled = newState
             }
        }
        
        Divider()
        
        Button("Faktor v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (latest)") {
        }.disabled(true)
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
        
    }
}

