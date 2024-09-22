//
//  MenuItemButtonStyle.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 9/21/24.
//


import SwiftUI

struct MenuItemButtonStyle: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 3)
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(hovering ? 1 : 0))
            .cornerRadius(4)
            .onTrackingHover { hovering in
                self.hovering = hovering
            }
            .environment(\.buttonPressed, configuration.isPressed)
            .environment(\.buttonHovered, hovering)
    }
}

struct MenuItemButtonStyleDisbled: ButtonStyle {
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 3)
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(hovering ? 1 : 0))
            .opacity(0.3)
            .cornerRadius(4)
            .environment(\.buttonPressed, configuration.isPressed)
    }
}

private struct ButtonPressedKey: EnvironmentKey {
    static let defaultValue = false
}

private struct ButtonHoveredKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var buttonPressed: Bool {
        get { self[ButtonPressedKey.self] }
        set { self[ButtonPressedKey.self] = newValue }
    }

    var buttonHovered: Bool {
        get { self[ButtonHoveredKey.self] }
        set { self[ButtonHoveredKey.self] = newValue }
    }
}
