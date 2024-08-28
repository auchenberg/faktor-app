import SwiftUI

import LaunchAtLogin
import Defaults

struct GeneralSettingsView: View {

    @Default(.settingsShowInDock) var showInDock
    @Default(.settingShowNotifications) var showNotifications
    @Default(.settingsEnableBrowserIntegration) var enableBrowserIntegration
        
    var body: some View {
        Form {
            Section("Application") {
                LaunchAtLogin.Toggle("Launch on login")
                .controlSize(.large)
                
                Toggle(isOn: $showInDock) {
                    Text("Show in Dock")
                }
                .controlSize(.large)
                .onChange(of: showInDock) { newValue in
                    Defaults[.settingsShowInDock] = newValue
                }
            }
            Section("Notifications") {
                Toggle(isOn: $showNotifications) {
                    Text("Show Notifications")
                }
                .controlSize(.large)
                .onChange(of: showNotifications) { newValue in
                    Defaults[.settingShowNotifications] = newValue
                }

                Toggle(isOn: $enableBrowserIntegration) {
                     Text("Enable browser extension")
                 }
                .controlSize(.large)
                .onChange(of: enableBrowserIntegration) { newValue in
                    Defaults[.settingsEnableBrowserIntegration] = newValue
                }                
            }
        
        }
        .formStyle(.grouped)
        .padding(40)
    }

}

struct GeneralTab_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
            .frame(width: 600)
            .frame(height: 500)
            .fixedSize()
    }
}
