//
//  settingsView.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 7/6/24.
//

import SwiftUI

enum SettingsTab: Int {
    case general = 0
    case about = 1
}

struct SettingsView: View {
    @AppStorage("SettingsSelectedTabIndex") var selectedTab: SettingsTab = .general
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
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
