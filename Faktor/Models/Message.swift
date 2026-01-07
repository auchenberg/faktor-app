//
//  Mesage.swift
//  Faktor
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation
import SQLite

struct Message: Equatable, Identifiable {
    let id = UUID()
    let guid: String
    let text: String
    let handle: String
    let group: String?
    let fromMe: Bool
    var isRead: Bool
}

typealias MessageWithParsedOTP = (Message, ParsedOTP)
