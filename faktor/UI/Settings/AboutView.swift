//
//  AboutSettingsView.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 7/6/24.
//

import SwiftUI

struct AboutSettingsView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        VStack() {
            Image(.icon)
                .resizable()
                .frame(width: 128, height: 128)
            
            Form {
                Section() {
                    List() {
                        HStack() {
                            Text("Version")
                            Spacer()
                            Text("\(appVersion ?? "0.0.1")")
                        }.padding(10)
                        
                        HStack {
                            Text("Website")
                            Spacer()
                            Link("getfaktor.com", destination: URL(string: "https://getfaktor.com")!)
                        }.padding(10)
                        
                        HStack() {
                            Text("Twitter / X")
                            Spacer()
                            Link("@auchenberg", destination: URL(string: "https://x.com/auchenberg")!)
                        }.padding(10)
                    }
                }
                
                Section("Reset") {
                    HStack {
                        Spacer()
                        Button("Reset data and quit") {
                            appStateManager.resetStateAndQuit()
                        }
                        .controlSize(.large)
                        Spacer()
                    }
                    .padding(.vertical)
                }
            }
            .formStyle(.grouped)
        }
        .padding(40)
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutSettingsView()
            .frame(width: 600)
            .frame(height: 500)
            .fixedSize()
    }
}
