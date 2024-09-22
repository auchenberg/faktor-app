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
import OSLog

struct AppMenu: View {
    
    @EnvironmentObject var messageManager: MessageManager
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var browserManager: BrowserManager
        
    var body: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            
            MenuHeader()
                .padding(9)
                .environmentObject(browserManager)
            
            if !appStateManager.hasRequiredPermissions() {
                Button("Start onboarding") {
                    appStateManager.startOnboarding()
                }
                    .buttonStyle(MenuItemButtonStyle())
            }
            
            if appStateManager.hasRequiredPermissions() {
                CodesView()
                    .environmentObject(messageManager)
                    .environmentObject(appStateManager)
                    .environmentObject(browserManager)
            }
            
            if appStateManager.isDevelopmentMode() {
                Divider()
                    .padding(.horizontal, 9)
                
                Button("DEBUG: Trigger new code") {
                    messageManager.generateRandomMessage()
                }
                    .buttonStyle(MenuItemButtonStyle())
            }
            
            Divider()
                .padding(.horizontal, 9)
            
            SettingsLink {
                Text("Settings...")
                    .keyboardShortcut(",")
            } preAction: {
                NSApp.activate(ignoringOtherApps: true)
            } postAction: {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(MenuItemButtonStyle())
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
                .keyboardShortcut("q")
                .buttonStyle(MenuItemButtonStyle())
            
        }
        .padding(5)
        .frame(width: 336)
        
    }
}
