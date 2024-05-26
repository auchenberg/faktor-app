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
    @State var recentMessages: [MessageWithParsedOTP]
    @Default(.settingShowNotifications) var showNotifications
    @Default(.settingsEnableBrowserIntegration) var enableBrowserIntegration
        
    func onCodeClicked() {
        print("TODO: Paste code to clipboard")
    }
        
    var body: some View {
            
        
        Button("Recent") {
            
        }.disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
        
        // List recent messages
        ForEach(recentMessages, id: \.0.guid) { message in
            Button(action: onCodeClicked, label: { Text(message.1.code) })
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

