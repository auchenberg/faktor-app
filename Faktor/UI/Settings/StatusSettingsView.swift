import SwiftUI

struct StatusSettingsView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @EnvironmentObject var browserManager: BrowserManager
    
    var body: some View {
        Form {
            Section("Faktor Status") {
                statusRow(
                    title: "Disk Access",
                    message: appStateManager.diskAccessState.displayMessage,
                    status: appStateManager.diskAccessState.requiresAction ? .error : .success
                ) {
        
                }
                
                statusRow(
                    title: "macOS notifications",
                    message: appStateManager.notificationState ? "macOS notifications are enabled" : "macOS notifications are disabled",
                    status: appStateManager.notificationState ? .success : .warning
                ) {
             
                }
                
                statusRow(
                    title: "Browser connections",
                    message: browserManager.getConnectedClientsSummary() != "" ? browserManager.getConnectedClientsSummary() :  "No browsers currently connected to Faktor",
                    status: browserManager.connectedWebSockets.count > 0 ? .success : .warning
                ) {
             
                }
                

            }
        }
        .formStyle(.grouped)
    }
    
    private func statusRow(
        title: String,
        message: String,
        status: StatusIndicator,
        @ViewBuilder action: @escaping () -> some View
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                StatusIndicatorView(status: status)
                action()
            }
        }
        .padding(.vertical, 4)
    }
    
    private var isDevelopmentMode: Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
}

// Helper enum for status indicators
enum StatusIndicator {
    case success
    case warning
    case error
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .yellow
        case .error: return .red
        }
    }
    
    var systemImage: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

// Status indicator view
struct StatusIndicatorView: View {
    let status: StatusIndicator
    
    var body: some View {
        Image(systemName: status.systemImage)
            .foregroundStyle(status.color)
    }
}

#Preview {
    StatusView()
        .frame(width: 500)
        .environmentObject(AppStateManager())
} 
