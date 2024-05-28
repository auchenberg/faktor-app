//
//  AppStateManager.swift
//  autho
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation
import ServiceManagement
import SwiftUI
import ApplicationServices
import FullDiskAccess

class AppStateManager: ObservableObject, Identifiable {
            
    func hasRequiredPermissions() -> Bool {
        FullDiskAccess.isGranted
    }
    
    func requestPermissions() {
        FullDiskAccess.promptIfNotGranted(
            title: "Enable Full Disk Access for Autho",
            message: "Autho requires Full Disk Access to search for new codes",
            settingsButtonTitle: "Open Settings",
            skipButtonTitle: "Later",
            canBeSuppressed: false,
            icon: nil
        )
    }

}
