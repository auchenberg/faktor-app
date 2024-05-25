////
////  data.swift
////  codefill
////
////  Created by Kenneth Auchenberg on 5/23/24.
////
//
//import Foundation
//import SQLite
//
//class Data {
//    private var db: Connection?
//    private let messagesTable = Table("messages")
//    private let id = Expression<Int64>("id")
//    private let text = Expression<String>("text")
//    private let timestamp = Expression<Date>("timestamp")
//
//    init(databaseName: String) {
//        do {
//            let path = try FileManager.default
//                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
//                .appendingPathComponent("\(databaseName).sqlite3")
//                .path
//
//            db = try Connection(path)
//        } catch {
//            print("Unable to open database. Error: \(error)")
//        }
//    }
//
//    public func getMostRecentTexts(limit: Int) -> [String] {
//        var texts: [String] = []
//
//        do {
//            guard let db = db else {
//                print("Database connection not initialized.")
//                return texts
//            }
//
//            let query = messagesTable.order(timestamp.desc).limit(limit)
//            for message in try db.prepare(query) {
//                if let messageText = try? message.get(text) {
//                    texts.append(messageText)
//                }
//            }
//        } catch {
//            print("Failed to fetch recent texts. Error: \(error)")
//        }
//
//        return texts
//    }
//}
