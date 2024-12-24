import SwiftUI
import LaunchAtLogin
import Defaults

struct GeneralSettingsView: View {
    @Default(.settingShowNotifications) var showNotifications
    @Default(.settingsEnableBrowserIntegration) var enableBrowserIntegration
    @Default(.settingsUseAIForParsing) var useFaktorAIForParsing
    @EnvironmentObject var appStateManager: AppStateManager
        
    var body: some View {
        Form {
            
            Section("Application") {
                LaunchAtLogin.Toggle("Launch on login")
                .controlSize(.large)
            
            }

            Section("Faktor AI") {
                Toggle("Use Faktor AI for smart code detection", isOn: $useFaktorAIForParsing)
                .controlSize(.large)
                .onChange(of: useFaktorAIForParsing) { newValue in
                    Defaults[.settingsUseAIForParsing] = newValue
                }   
            }

            Section("Notifications") {
                Toggle(isOn: $showNotifications) {
                    Text("Show notifications on new message")
                }
                .controlSize(.large)
                .onChange(of: showNotifications) { newValue in
                    Defaults[.settingShowNotifications] = newValue
                }

                Toggle(isOn: $enableBrowserIntegration) {
                     Text("Enable browser extension communication")
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
