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

enum FullDiskAccessStatus {
    case authorized, denied, unknown
}

class AppStateManager {
    static let shared = AppStateManager()
    
    private init() {}
    
    func hasFullDiscAccess() -> FullDiskAccessStatus {
        var homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        homeDirectory.appendPathComponent("/Library/Messages/chat.db")

        let fileExists = FileManager.default.fileExists(atPath: homeDirectory.path)
        let data = try? Data(contentsOf: homeDirectory)
        if data == nil && fileExists {
            return .denied
        } else if fileExists {
            return .authorized
        }
        
        return .unknown
    }
    
    func hasAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: false]
        let status = AXIsProcessTrustedWithOptions(options)
    
        return status
    }

    
    func hasRequiredPermissions() -> Bool {
        let fullDiskAccess = hasFullDiscAccess()
        
        // Check if both permissions are authorized
        return fullDiskAccess == .authorized
    }

}
