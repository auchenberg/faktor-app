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

struct AppMenu: View {
    
    @State private var isLaunchedAtLoginEnabled: Bool = LaunchAtLogin.isEnabled
    @ObservedObject var messageManager: MessageManager
    @Default(.settingShowNotifications) var showNotifications
    @Default(.settingsEnableBrowserIntegration) var enableBrowserIntegration
    
    func onCodeClicked(message: MessageWithParsedOTP) {
        message.1.copyToClipboard()
    }
    
    var body: some View {
        
        Button("Recent") {
        
        }.disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
        
        // List recent messages
        ForEach(messageManager.messages.reversed().prefix(3), id: \.0.guid) { message in
            Button(action: {onCodeClicked(message: message)}, label: { Text(message.1.code + " from " + message.1.service!) })
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
             .onChange(of:isLaunchedAtLoginEnabled) { oldState, newState in
                 print("Checkbox state is now: \(newState)")
                 LaunchAtLogin.isEnabled = newState
             }
            
        }
        
        Divider()
        
        Button("Autho v1.0.0 (latest)") {
        }.disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
        
        Button("Connected to iMessage") {
            
        }.disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
        
        
        Divider()
        
        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }.keyboardShortcut("q")
        
    }
}

