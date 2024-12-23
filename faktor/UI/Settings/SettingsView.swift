//
//  settingsView.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 7/6/24.
//

import SwiftUI

enum SettingsTab: Int {
    case general = 0
    case status = 1
    case permissions = 2
    case logs = 3
    case about = 4
}

struct SettingsView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var browserManager: BrowserManager

    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)
                .environmentObject(appStateManager)
                        
            PermissionsView()
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
                .tag(SettingsTab.permissions)
                .environmentObject(appStateManager)
            
            StatusSettingsView()
                .tabItem {
                    Label("Status", systemImage: "gauge")
                }
                .tag(SettingsTab.status)
                .environmentObject(appStateManager)
                .environmentObject(browserManager)
            
            LogsView()
                .tabItem {
                    Label("Logs", systemImage: "doc.text")
                }
                .tag(SettingsTab.logs)
            
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
                .environmentObject(appStateManager)
        }
        .frame(width: 600)
        .frame(maxHeight: 1200)
        .fixedSize()
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
