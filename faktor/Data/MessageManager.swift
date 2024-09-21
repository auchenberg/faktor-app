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

enum MessageManagerError: Error {
    case generic(message: String)
    case permission(message: String)
}

class MessageManager: ObservableObject, Identifiable {
    @Published var messages: [MessageWithParsedOTP] = []
    
    private let checkTimeInterval: TimeInterval = 1
    private var processedGuids: Set<String> = []
    
    var otpParser: OTPParser
    
    init() {    
        self.otpParser = OTPParser()
    }
    
    var timer: Timer?
    
    private func timeOffsetForDate(_ date: Date) -> Int {
        var appleOffsetForDate = Int(date.timeIntervalSinceReferenceDate)
        
        if #available(macOS 10.13, *) {
            // Check if the macOS version is 10.13 or later
            let factor = Int(pow(10.0, 9)) // Calculate 10^9 and convert it to an integer
            appleOffsetForDate *= factor   // Multiply appleOffsetForDate by the factor
        }
        
        return appleOffsetForDate
    }

    private func loadMessagesAfterDate(_ date: Date) throws -> [Message]? {
        Logger.core.info("messageManager.loadMessagesAfterDate: Attempting to load messages after \(date)")
        
        do {
            return try performDatabaseOperation { db in
                let textColumn = SQLite.Expression<String?>("text")
                let guidColumn = SQLite.Expression<String>("guid")
                let cacheRoomnamesColumn = SQLite.Expression<String?>("cache_roomnames")
                let fromMeColumn = SQLite.Expression<Bool>("is_from_me")
                let dateColumn = SQLite.Expression<Int>("date")
                let serviceColumn = SQLite.Expression<String>("service")
                let isReadColumn = SQLite.Expression<Bool>("is_read")
                
                let ROWID = SQLite.Expression<Int>("ROWID")

                let handleTable = Table("handle")
                let handleFrom = handleTable[SQLite.Expression<String?>("id")]
                let messageTable = Table("message")
                let messageHandleId = messageTable[SQLite.Expression<Int>("handle_id")]
                
                let query = messageTable
                    .select(messageTable[guidColumn], messageTable[fromMeColumn], messageTable[textColumn], messageTable[cacheRoomnamesColumn], messageTable[dateColumn], messageTable[isReadColumn], handleFrom, messageTable[serviceColumn])
                    .join(.leftOuter, handleTable, on: messageHandleId == handleTable[ROWID])
                    .where(messageTable[dateColumn] > self.timeOffsetForDate(date) && messageTable[serviceColumn] == "SMS")
                    .order(messageTable[dateColumn].asc)
                
                Logger.core.debug("messageManager.loadMessagesAfterDate: Executing query")
                
                let mapRowIterator = try db.prepareRowIterator(query)
                let messages = try mapRowIterator.compactMap { messageRow -> Message? in
                    guard let text = messageRow[textColumn], let handle = messageRow[handleFrom] else { return nil }
                    
                    return Message(
                        guid: messageRow[guidColumn],
                        text: text,
                        handle: handle,
                        group: messageRow[cacheRoomnamesColumn],
                        fromMe: messageRow[fromMeColumn],
                        isRead: messageRow[isReadColumn]
                    )
                }
                
                Logger.core.info("messageManager.loadMessagesAfterDate: Successfully loaded \(messages.count) messages")
                return messages
            }
        } catch let error as MessageManagerError {
            Logger.core.error("messageManager.loadMessagesAfterDate: MessageManagerError - \(error.localizedDescription)")
            throw error
        } catch {
            Logger.core.error("messageManager.loadMessagesAfterDate: Unexpected error - \(error.localizedDescription)")
            throw MessageManagerError.generic(message: "Failed to load messages: \(error.localizedDescription)")
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
        
        do {
            let parsedOtps = try findPossibleOTPMessagesAfterDate(modifiedDate)
            guard parsedOtps.count > 0 else { return }
            messages.append(contentsOf: parsedOtps)

        } catch let err {
            Logger.core.error("messageManager.syncMessages.error: \(err)")
        }
    }
    
    private func findPossibleOTPMessagesAfterDate(_ date: Date) throws -> [MessageWithParsedOTP] {
        if let messagesFromDB = (try loadMessagesAfterDate(date)) {
            let filteredMessages = messagesFromDB
                .filter { !$0.fromMe }
                .filter { !isInvalidMessageBodyValidPerCustomBlacklist($0.text) }
                .filter { !processedGuids.contains($0.guid) }
            
            filteredMessages.forEach { message in
                processedGuids.insert(message.guid)
            }
                    
            return filteredMessages.compactMap { message in
                guard let parsedOTP = otpParser.parseMessage(message.text) else { return nil }
                return (message, parsedOTP)
            }
        } else {
            Logger.core.error("messageManager.findPossibleOTPMessagesAfterDate.error: No messages found or an error occurred.")
            return []
        }
    }
    
    private func isInvalidMessageBodyValidPerCustomBlacklist(_ messageBody: String) -> Bool {
        return (
            messageBody.isEmpty ||
            messageBody.count < 5 ||
            messageBody.contains("$") ||
            messageBody.contains("€") ||
            messageBody.contains("₹") ||
            messageBody.contains("¥")
        )
    }
    
    private func performDatabaseOperation<T>(_ operation: (Connection) throws -> T) throws -> T {
        Logger.core.info("messageManager.performDatabaseOperation")
        
        guard let bookmarkData = Defaults[.libraryFolderBookmark] else {
            Logger.core.error("messageManager.performDatabaseOperation.error: No bookmark data found")
            throw MessageManagerError.permission(message: "No bookmark data found")
        }
        
        var bookmarkDataIsStale = false
        let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &bookmarkDataIsStale)
        
        if bookmarkDataIsStale {
            Logger.core.error("messageManager.performDatabaseOperation.error: Bookmark data is stale")
            throw MessageManagerError.permission(message: "Bookmark data is stale")
        }
        
        if url.startAccessingSecurityScopedResource() {
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let dbUrl = url.appendingPathComponent("/Messages/chat.db")
            let db = try Connection(dbUrl.absoluteString)
            
            Logger.core.info("messageManager.performDatabaseOperation.success")
            return try operation(db)
        } else {
            Logger.core.error("messageManager.performDatabaseOperation.error: Failed to start accessing security scoped resource")
            throw MessageManagerError.permission(message: "Failed to start accessing security scoped resource")
        }
    }

    func markMessageAsRead(message: MessageWithParsedOTP) {
//        try performDatabaseOperation { db in
//            let messageTable = Table("message")
//            let guidColumn = Expression<String>("guid")
//            let isReadColumn = Expression<Bool>("is_read")
//
//            let guid = message.0.guid
//            
//            let updateStatement = messageTable.filter(guidColumn == guid).update(isReadColumn <- true)
//            try db.run(updateStatement)
//            
//            // Update the local messages array
//            if let index = self.messages.firstIndex(where: { $0.0.guid == guid }) {
//                self.messages[index].0.isRead = true
//            }
//            
//            Logger.core.info("Message with GUID \(guid) marked as read")
//        }
    }
    
    func copyOTPToClipboard(message: MessageWithParsedOTP) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(message.1.code, forType: .string)
    }
}

