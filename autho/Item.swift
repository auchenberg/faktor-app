//
//  Item.swift
//  autho
//
//  Created by Kenneth Auchenberg on 5/24/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
