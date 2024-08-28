//
//  OnboardingView.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import Foundation

import SwiftUI

struct OnboardingView: View {
//    @Environment(\.customWindowPresentation) private var customWindowPresentation

    var body: some View {
        VStack(alignment: .center, spacing: 36) {
            VStack(spacing: 8) {
                Image("Icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 128)

                Text("Welcome to Faktor")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundColor(.primary)

                if let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version \(marketingVersion)")
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 0) {
                Text("To get started please complete the following items:")
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 56)

                OnboardingTaskList()

                VStack(spacing: 32) {
                    Button("Start Using Faktor") {
//                        customWindowPresentation?.dismiss()
                    }
                    .controlSize(.large)
                    .keyboardShortcut(.return)
                }
            }
        }
        .padding(.top, 56)
        .padding(.horizontal, 8)
        .padding(.bottom, 28)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
