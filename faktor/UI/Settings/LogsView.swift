import SwiftUI
import OSLog

struct LogsView: View {
    @State private var logs: [OSLogEntry] = []
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText)
            
            if filteredLogs.isEmpty {
                EmptyLogsView()
            } else {
                List {
                    ForEach(filteredLogs, id: \.self) { log in
                        LogEntryRow(log: log)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
//        .onAppear(perform: fetchLogs)
        .padding()
    }
    
    private var filteredLogs: [OSLogEntry] {
        if searchText.isEmpty {
            return logs
        } else {
            return logs.filter { $0.composedMessage.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private func fetchLogs() {
        // Fetch logs from OSLog
        let logStore = try? OSLogStore(scope: .currentProcessIdentifier)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let position = logStore?.position(date: oneHourAgo)
        
        if let entries = try? logStore?.getEntries(at: position) {
            self.logs = Array(entries)
        }
    }
}

struct EmptyLogsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("No logs available")
                .font(.headline)
            Text("Logs will appear here as they are generated")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search logs...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct LogEntryRow: View {
    let log: OSLogEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(log.composedMessage)
                .font(.body)
            Text(log.date, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
