//
//  OTPParserPerformanceTests.swift
//  FaktorTests
//
//  Performance tests for OTP parsing
//

import XCTest
@testable import Faktor

final class OTPParserPerformanceTests: XCTestCase {

    var parser: OTPParser!

    override func setUp() {
        super.setUp()
        parser = OTPParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Performance Tests

    func test_performance_parseSimpleCode() {
        measure {
            for _ in 0..<100 {
                _ = parser.parseMessage("Your verification code is 123456")
            }
        }
    }

    func test_performance_parseGoogleCode() {
        measure {
            for _ in 0..<100 {
                _ = parser.parseMessage("G-412157 is your Google verification code.")
            }
        }
    }

    func test_performance_parseComplexMessage() {
        let message = "Your WhatsApp code is 105-876 but you can simply tap on this link to verify your device: v.whatsapp.com/105876"
        measure {
            for _ in 0..<100 {
                _ = parser.parseMessage(message)
            }
        }
    }

    func test_performance_parseMessageWithNoCode() {
        let message = "Thank you for your purchase! Your order will arrive in 3-5 business days."
        measure {
            for _ in 0..<100 {
                _ = parser.parseMessage(message)
            }
        }
    }

    func test_performance_parseLongMessage() {
        let message = """
        Welcome to our service! We are so excited to have you on board.
        Your verification code is 987654. Please enter this code within 10 minutes.
        If you did not request this code, please ignore this message.
        For help, contact support@example.com or call 1-800-555-1234.
        """
        measure {
            for _ in 0..<100 {
                _ = parser.parseMessage(message)
            }
        }
    }
}
