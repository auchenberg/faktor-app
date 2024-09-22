//
//  settingsView.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 7/6/24.
//

import SwiftUI

enum SettingsTab: Int {
    case general = 0
    case permissions = 1
    case logs = 2
    case about = 3
}

struct SettingsView: View {
    @AppStorage("SettingsSelectedTabIndex") var selectedTab: SettingsTab = .general
    @EnvironmentObject var appStateManager: AppStateManager
    
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
