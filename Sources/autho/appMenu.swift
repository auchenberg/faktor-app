//
//  AppMenu.swift
//  codefill
//
//  Created by Kenneth Auchenberg on 5/23/24.
//

import SwiftUI
import Foundation

struct AppMenu: View {

    
    func action1() {
        
    }
    func action2() {
        
    }
    func action3() {
        
    }

    var body: some View {
        Menu("Recent Codes") {
            Button(action: action1, label: { Text("Code 1") })
            Button(action: action1, label: { Text("Code 2") })
        }
        Menu("Preferences") {
            Toggle(isOn: .constant(true)) {
                 Text("Show Notifications")
             }
             .toggleStyle(.checkbox)
            Toggle(isOn: .constant(true)) {
                 Text("Enable browser integration")
             }
             .toggleStyle(.checkbox)
        }

        Divider()
        
        Button(action: action3, label: { Text("Autho v1.0.0 (latest)") } ).disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
        
        Divider()

        Button(action: action3, label: { Text("Quit") })
    }
}

