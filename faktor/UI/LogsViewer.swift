//
//  LogsViewer.swift
//  faktor
//
//  Created by Kenneth Auchenberg on 7/7/24.
//

import Foundation
import OSLog
import SwiftUI

struct LogsViewer: View {
    let logs: [OSLogEntryLog]

    init() {
        let logStore = try! OSLogStore(scope: .currentProcessIdentifier)
        self.logs = try! logStore.getEntries().compactMap { entry in
            guard let logEntry = entry as? OSLogEntryLog,
                  logEntry.subsystem.starts(with: "com.auchenberg.faktor") == true else {
                return nil
            }

            return logEntry
        }
    }

    var body: some View {
        List(logs, id: \.self) { log in
            VStack(alignment: .leading) {
                Text(log.composedMessage)
                HStack {
                    Text(log.subsystem)
                    Text(log.date, format: .dateTime)
                }.bold()
            }
        }
    }
}
