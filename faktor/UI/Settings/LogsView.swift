import SwiftUI
import OSLog

struct LogsView: View {
    @State private var logs: [OSLogEntryLog] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            Form {
                Section() {
                    VStack {
                        if isLoading {
                            LoadingView()
                        } else if logs.isEmpty {
                            EmptyLogsView()
                        } else {
                            List {
                                ForEach(logs, id: \.self) { log in
                                    LogEntryRow(log: log)
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                    .onAppear(perform: fetchLogs)
                }
            }
            .formStyle(.grouped)
            .frame(maxHeight: 400)
        }.padding(40)
    }
        
    private func fetchLogs() {
        isLoading = true
        
        let subsystem = Bundle.main.bundleIdentifier!
        
        // Fetch logs from OSLog
        guard let logStore = try? OSLogStore(scope: .currentProcessIdentifier) else {
            print("Error: Unable to create OSLogStore")
            isLoading = false
            return
        }
        
        let oneHourAgo = Date().addingTimeInterval(-3600)
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let position = logStore.position(date: oneHourAgo)
                
                let allEntries = try logStore.getEntries(at: position)
                let filteredLogs = allEntries.compactMap { entry -> OSLogEntryLog? in
                    guard let logEntry = entry as? OSLogEntryLog,
                          logEntry.subsystem == subsystem else {
                        return nil
                    }
                    return logEntry
                }
                
                DispatchQueue.main.async {
                    self.logs = filteredLogs
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error fetching logs: \(error)")
                    self.isLoading = false
                }
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1)
                .padding()
            Text("Loading logs...")
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyLogsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No logs available yet")
                .font(.headline)
            Text("Logs will appear here as they are generated")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LogEntryRow: View {
    let log: OSLogEntryLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(log.date, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            Text(logTypeString(for: log.level))
                .font(.caption)
                .foregroundColor(logTypeColor(for: log.level))
                .frame(width: 40, alignment: .leading)
            
            Text(log.composedMessage)
                .font(.body)
                .lineLimit(nil)
        }
        .padding(.vertical, 4)
    }
    
    private func logTypeString(for level: OSLogEntryLog.Level) -> String {
        switch level {
        case .undefined:
            return "Undefined"
        case .debug:
            return "Debug"
        case .info:
            return "Info"
        case .notice:
            return "Notice"
        case .error:
            return "Error"
        case .fault:
            return "Fault"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func logTypeColor(for level: OSLogEntryLog.Level) -> Color {
        switch level {
        case .undefined:
            return .gray
        case .debug:
            return .blue
        case .info:
            return .green
        case .notice:
            return .yellow
        case .error:
            return .red
        case .fault:
            return .red
        @unknown default:
            return .gray
        }
    }
}
