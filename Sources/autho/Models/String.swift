//
//  String.swift
//  autho
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation

extension String {
    var withNonDigitsRemoved: Self? {
        guard let regExp = try? NSRegularExpression(pattern: #"[^\d.]"#, options: .caseInsensitive) else { return nil }
        let range = NSRange(location: 0, length: self.utf16.count)

        // Replace non-digits and non-decimal points with an empty string
        let cleanedString = regExp.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        
        // Check if the cleaned string contains a decimal point
        if cleanedString.contains(".") {
            // If it does, return the cleaned string
            return cleanedString
        } else {
            // Otherwise, return nil to indicate that the original string should be used
            return nil
        }
    }
}

extension String {
  var isBlank: Bool {
    return allSatisfy({ $0.isWhitespace })
  }
}
