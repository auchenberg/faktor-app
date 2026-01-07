//
//  :NSApplication+ShowSettingsWindow.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 8/20/24.
//

import AppKit

extension NSApplication {
    func showSettingsWindow() {
        activate(ignoringOtherApps: true)
        sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
