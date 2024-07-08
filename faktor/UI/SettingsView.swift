//
//  settingsView.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 7/6/24.
//

import SwiftUI

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general, about, snippet
    }
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
                .padding(10)
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "timelapse")
                }
                .tag(Tabs.about)
                .padding(10)
        }
        .padding(20)
        .frame(width: 840, height: 500)
    }
}
