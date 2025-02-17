import SwiftUI

import PostHog


struct CodesView: View {
    @EnvironmentObject var messageManager: MessageManager
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var browserManager: BrowserManager
        
    func onCodeClicked(message: MessageWithParsedOTP) {
        PostHogSDK.shared.capture("faktor.copyToClipboard")
        browserManager.sendNotificationToBrowsers(message: message)
        messageManager.copyOTPToClipboard(message: message)
        Task {
            await messageManager.markMessageAsRead(message: message)
        }
        
        // Find and close the "Faktor" window
        // TODO: Find better way as this is hacky
        if let faktorWindow = NSApplication.shared.windows.first(where: { $0.title == "Faktor" }) {
            faktorWindow.close()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("Recent codes")
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 9)
            .padding(.top, 3)
            .padding(.bottom, 3)
            
            if messageManager.messages.isEmpty {
                Text("No recent codes found")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                    .padding(.horizontal, 9)
                    .padding(.top, 3)
                    .padding(.bottom, 3)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(messageManager.messages.reversed().prefix(3), id: \.0.guid) { message in
                        Button(action: { self.onCodeClicked(message: message) }, label: {
                            HStack(alignment: .center, spacing: 9) {
                                Image(systemName: "lock.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .font(.body)
                                    .frame(width: 26, height: 26)
                                    .cornerRadius(.infinity)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(message.1.code)
                                        .foregroundColor(.primary)
                                    
                                    Text((message.1.service ?? "unknown"))
                                        .font(.caption2)
                                        .opacity(0.8)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.trailing, 6)
                        })
                        .buttonStyle(MenuItemButtonStyle())
                    }
                }
            }
        }
    }
}
