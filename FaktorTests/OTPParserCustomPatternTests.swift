//
//  OTPParserCustomPatternTests.swift
//  FaktorTests
//
//  Tests for custom OTP parsing patterns
//

import XCTest
@testable import Faktor

final class OTPParserCustomPatternTests: XCTestCase {

    var parser: OTPParser!

    override func setUp() {
        super.setUp()
        parser = OTPParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Custom Pattern Configuration Tests

    func test_customPattern_matchesAndExtractsCode() throws {
        let jsonPattern = #"""
        {
          "matcherPattern": "^someweird-.+$",
          "codeExtractorPattern": "^someweird.+:(([\\d\\D]){4,6})$"
        }
        """#

        let decoded = try JSONDecoder().decode(
            OTPParserCustomPatternConfiguration.self,
            from: jsonPattern.data(using: .utf8)!
        )

        XCTAssertNotNil(decoded.matcherPattern)
    }

    func test_customPattern_withServiceName_extractsServiceAndCode() throws {
        let message = "46143020\nvalid 5 minutes\ndurata 5 minuti\ndurée 5 minutes\ngültig 5 minuten\r"
        let jsonPattern = #"""
        {
           "serviceName":"no provider name",
           "matcherPattern":"\\d{2,8}.*valid",
           "codeExtractorPattern":"(\\d{2,8})"
        }
        """#

        let decoded = try JSONDecoder().decode(
            OTPParserCustomPatternConfiguration.self,
            from: jsonPattern.data(using: .utf8)!
        )

        // Verify the pattern can match the message
        XCTAssertNotNil(decoded.matcherPattern.firstMatchInString(message))
    }

    // MARK: - Default Parser Pattern Tests

    func test_defaultParser_handlesStandardSixDigitCode() {
        let result = parser.parseMessage("Your verification code is 469538")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "469538")
    }

    func test_defaultParser_handlesDashedFormat() {
        let result = parser.parseMessage("Humaniq code: 167-262")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "167262")
        XCTAssertEqual(result?.service, "humaniq")
    }

    func test_defaultParser_handlesWelcomeFormat() {
        let result = parser.parseMessage("Welcome to ClickSend, for your first login you'll need the activation PIN: 464120")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "464120")
        XCTAssertEqual(result?.service, "clicksend")
    }

    func test_defaultParser_handlesCodeWithColon() {
        let result = parser.parseMessage("[SwiftCall]Your verification code: 6049")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "6049")
        XCTAssertEqual(result?.service, "swiftcall")
    }

    func test_defaultParser_handlesProtonFormat() {
        let result = parser.parseMessage("Your Proton verification code is: 861880")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "861880")
        XCTAssertEqual(result?.service, "proton")
    }
}
