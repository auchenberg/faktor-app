//
//  ParsedOTP.swift
//  Faktor
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation

public struct ParsedOTP {
    public init(service: String?, code: String) {
        self.service = service
        self.code = code
    }
    
    public let service: String?
    public let code: String
}

extension ParsedOTP: Equatable {
    static public func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.service == rhs.service && lhs.code == rhs.code
    }
}
