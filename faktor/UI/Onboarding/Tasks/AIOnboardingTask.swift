//
//  DiskAccessOnboardingItem.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import Foundation
import SwiftUI
import Defaults

struct AIOnboardingTask: View {
    @ObservedObject var appStateManager: AppStateManager
    @State private var isAIEnabled: Bool = Defaults[.settingsUseAIForParsing]

    var body: some View {
        OnboardingItemLayout(
            title: "Use Faktor AI for smart code detection",
            description: "Faktor can optionally leverage AI to generate intelligent code patterns, particularly useful for non-English messages."
        ) {

        } actionView: {

            Toggle("", isOn: $isAIEnabled)
                .onChange(of: isAIEnabled) { newValue in
                    Defaults[.settingsUseAIForParsing] = newValue
                }
                .controlSize(.large)
  
        } content: {
            OnboardingItemStatusIcon(state: isComplete ? .complete : .warning) {

            }
        }
    }

    private var isComplete: Bool {
        self.appStateManager.hasNotificationPermissions()
    }
}
