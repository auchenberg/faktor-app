//
//  StatusView.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 9/21/24.
//


import SwiftUI

struct StatusView: View {
    @EnvironmentObject var browserManager: BrowserManager
    @EnvironmentObject var appStateManager: AppStateManager
    
    @State private var popoverPresented = false

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(mainStatusText)
                .lineLimit(1)
                .truncationMode(.tail)
                .id(mainStatusText)
                .transition(.push(from: .top).animation(.easeInOut))
                .animation(.easeInOut, value: mainStatusText)
                .foregroundColor(.secondary)
                .font(.callout.weight(.semibold))
        }
    }

    private var mainStatusText: String {
        let summary = browserManager.getConnectedClientsSummary()
        
        if !appStateManager.hasRequiredPermissions() {
            return "Onboarding required"
        } else if !summary.isEmpty {
            return summary
        } else {
            return "Ready"
        }
    }
}
