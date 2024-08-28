//
//  DiskAccessOnboardingItem.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import Foundation
import SwiftUI

struct DiskAccessOnboardingTask: View {
    @Environment(\.controlActiveState) private var controlActiveState
//    @Environment(\.appStateManager) private var appStateManager
    @State private var isComplete = Self.isCommandLineToolReachable

    var body: some View {
        OnboardingItemLayout(
            title: "Disk access to your library folder",
            description: "Faktor requires disk access to your library folder to search for new 2fa codes"
        ) {
            Image("Xcode")
                .resizable()
                .interpolation(.high)
        } infoPopoverContent: {
            OnboardingPopoverContent(title: "Disk access") {
                Text("In order for Faktor to search for new 2FA Codes, we need access to your library folder, where iMesssage stores it's messages.")
                    .lineLimit(3, reservesSpace: true)
            }
        } content: {
            OnboardingItemStatusIcon(state: isComplete ? .complete : .warning) {
                OnboardingPopoverContent(title: "Needs Setup") {
                    Text("Faktor requires disk access to your library folder to search for new 2fa codes")
                        .lineLimit(2, reservesSpace: true)
                }
            }
        }
        .onChange(of: controlActiveState) { newValue in
            if newValue == .key {
                updateStatus()
            }
        }
    }

    private func updateStatus() {
        let newValue = Self.isCommandLineToolReachable

        if self.isComplete != newValue {
            self.isComplete = newValue
        }
    }

    private static var isCommandLineToolReachable: Bool {
        false
//        URL(filePath: "/usr/bin/xcrun").isReachable()
    }
}
