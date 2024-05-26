//
//  Mesage.swift
//  autho
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation
import SQLite

struct Message: Equatable {
    let guid: String
    let text: String
    let handle: String
    let group: String?
    let fromMe: Bool
}

typealias MessageWithParsedOTP = (Message, ParsedOTP)
