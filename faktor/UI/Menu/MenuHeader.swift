//
//  MenuHeader.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 9/21/24.
//

import SwiftUI

struct MenuHeader: View {
    @EnvironmentObject var browserManager: BrowserManager
    
    var body: some View {
        HStack(alignment: .center) {
            
            let label = "Faktor"
            
            Text(label)
                .font(.body.bold())
                .foregroundColor(.primary)
            

            Spacer()

          StatusView()
                .environmentObject(browserManager)
        }
    }
}
