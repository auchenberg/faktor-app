//
//  authoApp.swift
//  autho
//
//  Created by Kenneth Auchenberg on 5/24/24.
//

import SwiftUI
import SwiftData

@main
struct authoApp: App {
    
    var body: some Scene {
        
        MenuBarExtra("Autho", systemImage: "lock.rectangle") {
            AppMenu()
        }
    
    }
}
