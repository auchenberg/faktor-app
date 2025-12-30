//
//  data.swift
//  codefill
//
//  Created by Kenneth Auchenberg on 5/23/24.
//

import Foundation
import SQLite
import Defaults
import OSLog
import AppKit

struct MessageManagerError: Error {
    let message: String
}

// Static column definitions for Messages database
private enum MessageColumns {
    static let text = SQLite.Expression<String?>("text")
    static let guid = SQLite.Expression<String>("guid")
    static let cacheRoomnames = SQLite.Expression<String?>("cache_roomnames")
    static let fromMe = SQLite.Expression<Bool>("is_from_me")
    static let date = SQLite.Expression<Int>("date")
    static let service = SQLite.Expression<String>("service")
    static let isRead = SQLite.Expression<Bool>("is_read")
    static let rowId = SQLite.Expression<Int>("ROWID")
    static let handleId = SQLite.Expression<Int>("handle_id")
    static let handleIdentifier = SQLite.Expression<String?>("id")

    static let messageTable = Table("message")
    static let handleTable = Table("handle")
}

class MessageManager: ObservableObject {
    @Published var messages: [MessageWithParsedOTP] = []

    private let checkTimeInterval: TimeInterval = 1
    private var processedGuids: Set<String> = []
    private let otpParser: OTPParserProtocol
    private let databaseQueue = DispatchQueue(label: "app.faktor.database", qos: .userInitiated)
    private var dbConnection: Connection?

    init() {
        self.otpParser = OTPParserFactory.createParser()
        self.dbConnection = try? createConnection()
    }

    private func createConnection() throws -> Connection {
        let dbUrl = getDatabaseURL()
        let db = try Connection(dbUrl.absoluteString, readonly: true)
        try db.execute("PRAGMA busy_timeout = 1000")
        return db
    }

    var timer: Timer?
    
    private func timeOffsetForDate(_ date: Date) -> Int {
        return Int(date.timeIntervalSinceReferenceDate * 1_000_000_000)
    }

    private func loadMessagesAfterDate(_ date: Date) async throws -> [Message]? {
        let dateOffset = self.timeOffsetForDate(date)

        return try await performDatabaseRead { db in
            let C = MessageColumns.self
            let handleFrom = C.handleTable[C.handleIdentifier]

            let query = C.messageTable
                .select(C.messageTable[C.guid], C.messageTable[C.fromMe], C.messageTable[C.text],
                        C.messageTable[C.cacheRoomnames], C.messageTable[C.date], C.messageTable[C.isRead],
                        handleFrom, C.messageTable[C.service])
                .join(.leftOuter, C.handleTable, on: C.messageTable[C.handleId] == C.handleTable[C.rowId])
                .where(C.messageTable[C.date] > dateOffset && C.messageTable[C.service] == "SMS")
                .order(C.messageTable[C.date].asc)

            let rows = try db.prepareRowIterator(query)
            return try rows.compactMap { row -> Message? in
                guard let text = row[C.text], let handle = row[handleFrom] else { return nil }
                return Message(
                    guid: row[C.guid],
                    text: text,
                    handle: handle,
                    group: row[C.cacheRoomnames],
                    fromMe: row[C.fromMe],
                    isRead: row[C.isRead]
                )
            }
        }
    }
    
    func startListening() {
        Logger.core.info("messageManager.startListening")
        syncMessages()

        timer = Timer.scheduledTimer(withTimeInterval: checkTimeInterval, repeats: true) { [weak self] _ in
            self?.syncMessages()
        }
    }
    
    func stopListening() {
        timer?.invalidate()
        
        timer = nil
    }
    
    func reset() {
        stopListening()
        messages = []
        processedGuids = []
        startListening()
    }

    func generateRandomMessage() {

        let randomMessage = Message(
            guid: UUID().uuidString,
            text: "Your code is \(Int.random(in: 1000...9999)) from Auchenberg Bank",
            handle: "random",
            group: nil, 
            fromMe: false,
            isRead: false
        )

        messages.append((randomMessage , ParsedOTP(service: "Auchenberg Bank", code: "\(Int.random(in: 1000...9999))")))
    }
    
    @objc func syncMessages() {
        Logger.core.info("messageManager.syncMessages")
        guard let modifiedDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date()) else { return }
        
        Task {
            do {
                let parsedOtps = try await findPossibleOTPMessagesAfterDate(modifiedDate)
                if parsedOtps.count > 0 {
                    await MainActor.run {
                        messages.append(contentsOf: parsedOtps)
                    }
                }
            } catch {
                Logger.core.error("messageManager.syncMessages.error: \(error)")
            }
        }
    }
    
    private func findPossibleOTPMessagesAfterDate(_ date: Date) async throws -> [MessageWithParsedOTP] {
        if let messagesFromDB = try await loadMessagesAfterDate(date) {
            let filteredMessages = messagesFromDB
                .filter { !$0.fromMe }
                .filter { !shouldSkipMessage($0.text) }
                .filter { !processedGuids.contains($0.guid) }
            
            filteredMessages.forEach { message in
                processedGuids.insert(message.guid)
            }
                
            var results: [MessageWithParsedOTP] = []
            for message in filteredMessages {
                if let parsedOTP = try? await otpParser.parseMessage(message.text) {
                    results.append((message, parsedOTP))
                }
            }
            return results
        } else {
            Logger.core.error("messageManager.findPossibleOTPMessagesAfterDate.error: No messages found or an error occurred.")
            return []
        }
    }
    
    private func shouldSkipMessage(_ text: String) -> Bool {
        return text.isEmpty ||
            text.count < 5 ||
            text.contains("$") ||
            text.contains("€") ||
            text.contains("₹") ||
            text.contains("¥")
    }
    
    private func performDatabaseRead<T: Sendable>(_ operation: @escaping @Sendable (Connection) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            databaseQueue.async { [self] in
                do {
                    // Reuse existing connection or create new one
                    let db: Connection
                    if let existing = self.dbConnection {
                        db = existing
                    } else {
                        db = try self.createConnection()
                        self.dbConnection = db
                    }
                    let result = try operation(db)
                    continuation.resume(returning: result)
                } catch {
                    // Connection may be stale, clear it for next attempt
                    self.dbConnection = nil
                    Logger.core.error("messageManager.performDatabaseRead: \(error)")
                    continuation.resume(throwing: MessageManagerError(message: error.localizedDescription))
                }
            }
        }
    }

    private func getDatabaseURL() -> URL {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        return homeDirectory.appending(path: "Library/Messages/chat.db")
    }

    /// Mark a message as read using AppleScript
    @discardableResult
    func markMessageAsRead(message: MessageWithParsedOTP) -> Bool {
        let handle = message.0.handle
        Logger.core.info("messageManager.markMessageAsRead: handle: \(handle)")

        let script = """
        tell application "Messages"
            set chatList to every chat
            repeat with aChat in chatList
                if id of aChat contains "\(handle)" then
                    return id of aChat
                end if
            end repeat
            return "not_found"
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)

            if let error = error {
                Logger.core.warning("messageManager.markMessageAsRead: AppleScript error - \(error)")
                return false
            }

            let resultString = result.stringValue ?? "nil"
            Logger.core.info("messageManager.markMessageAsRead: result - \(resultString)")
            return resultString != "not_found"
        }

        return false
    }   
    
    func copyOTPToClipboard(message: MessageWithParsedOTP) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.1.code, forType: .string)
    }
}

