//
//  OnboardingTaskList.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import Foundation
import SwiftUI

struct OnboardingTaskList: View {
    @Environment(\.controlActiveState) private var controlActiveState
    @EnvironmentObject var appStateManager: AppStateManager

    var body: some View {
        Form {
            Section {
                DiskAccessOnboardingTask(appStateManager: appStateManager)
            }

            Section {
                NotificationsOnboardingTask(appStateManager: appStateManager)
            }
            
            Section {
                BrowserExtensionOnboardingTask(appStateManager: appStateManager)
            }
        }
        .formStyle(.grouped)
        .scrollDisabled(true)
        .onChange(of: controlActiveState) { newValue in
            if newValue == .key {
                // Tells UtilityPathPreferences to notify subscribers
                // that it has changed so that they can update accordingly.
//                utilityPathPreferences.refresh()
            }
        }
    }
}


struct OnboardingTaskList_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingTaskList()
    }
}


