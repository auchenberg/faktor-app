//
//  AboutSettingsView.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 7/6/24.
//

import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let linkUrlString = "https://getfaktor.com"
        VStack {
            Image("AppIcon")
                .resizable()
                .frame(width: 128, height: 128)
            Text("Faktor")
                .font(.custom("HeadLineA", size: 25))
            Text("Version: \(appVersion ?? "0.0.1")")
                .padding(.top, 10.0)
            HStack {
                Link(linkUrlString, destination: URL(string: linkUrlString)!)
            }
        }
    }
}

struct AdvancedSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutSettingsView()
    }
}
