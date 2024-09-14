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
import SettingsAccess

struct AppMenu: View {
    
    @ObservedObject var messageManager: MessageManager
    @ObservedObject var appStateManager: AppStateManager
    @ObservedObject var browserManager: BrowserManager
    
    func onCodeClicked(message: MessageWithParsedOTP) {
        PostHogSDK.shared.capture("faktor.copyToClipboard")
        try! browserManager.sendNotificationToBrowsers(message: message)
        try! messageManager.copyOTPToClipboard(message: message)
        try! messageManager.markMessageAsRead(message: message)
    }
    
    var body: some View {

        if !appStateManager.hasRequiredPermissions() {
            Button("Start onboarding") {
                appStateManager.startOnboarding()
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
        
        SettingsLink {
          Text("Settings")
                .keyboardShortcut(",")
        } preAction: {
            NSApp.activate(ignoringOtherApps: true)
        } postAction: {
            NSApp.activate(ignoringOtherApps: true)
        }
        
        Divider()
        
        Button("Faktor v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")") {
        }.disabled(true)
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
        
    }
}

