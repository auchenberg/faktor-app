//
//  DiskAccessOnboardingItem.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import Foundation
import SwiftUI

struct DiskAccessOnboardingTask: View {
    @ObservedObject var appStateManager: AppStateManager

    var body: some View {
        OnboardingItemLayout(
            title: "Disk access to your library folder",
            description: "Faktor requires disk access to your library folder to search for new 2fa codes"
        ) {
            Image("Xcode")
                .resizable()
                .interpolation(.high)
        } actionView: {
            if !isComplete {
                VStack(alignment: .trailing, spacing: 10) {
                        Button("Grant full disk access") {
                            self.appStateManager.requestFullDiskAccess()
                        }.buttonStyle(.borderedProminent)
                    }
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
        self.appStateManager.hasLibraryAccessPermissions()
    }
}
