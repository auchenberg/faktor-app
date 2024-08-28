//
//  DiskAccessOnboardingItem.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import Foundation
import SwiftUI

struct NotificationsOnboardingTask: View {
    @ObservedObject var appStateManager: AppStateManager

    var body: some View {
        OnboardingItemLayout(
            title: "Allow Faktor to show notifications",
            description: "Faktor requires permissions to show notifications on your Mac."
        ) {
            Image("Xcode")
                .resizable()
                .interpolation(.high)
        } actionView: {
            if !isComplete {
                Button("Allow") {
                    Task {
                        await self.appStateManager.requestNotificationPermission()
                    }
                }.buttonStyle(.borderedProminent)
            }
        } content: {
            OnboardingItemStatusIcon(state: isComplete ? .complete : .warning) {
                OnboardingPopoverContent(title: "Needs Setup") {
                    Text("Faktor requires disk access to your library folder to search for new 2fa codes")
                        .lineLimit(2, reservesSpace: true)
                }
            }
        }
    }

    private var isComplete: Bool {
        self.appStateManager.hasNotificationPermissions()
    }
}
