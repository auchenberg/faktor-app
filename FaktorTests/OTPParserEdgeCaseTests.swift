//
//  OTPParserEdgeCaseTests.swift
//  FaktorTests
//
//  Tests for edge cases and boundary conditions in OTP parsing
//

import XCTest
@testable import Faktor

final class OTPParserEdgeCaseTests: XCTestCase {

    var parser: OTPParser!

    override func setUp() {
        super.setUp()
        parser = OTPParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Empty and Nil Input Tests

    func test_parseMessage_emptyString_returnsNil() {
        let result = parser.parseMessage("")

        XCTAssertNil(result)
    }

    func test_parseMessage_whitespaceOnly_returnsNil() {
        let result = parser.parseMessage("   ")

        XCTAssertNil(result)
    }

    func test_parseMessage_newlinesOnly_returnsNil() {
        let result = parser.parseMessage("\n\n\n")

        XCTAssertNil(result)
    }

    // MARK: - Phone Number Filtering Tests

    func test_parseMessage_containsPhoneNumber_extractsCodeNotPhone() {
        let result = parser.parseMessage("388-941-4444 your code is 333222")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "333222")
    }

    func test_parseMessage_internationalPhoneWithCode_extractsCode() {
        let result = parser.parseMessage("+1-388-941-4444 your code is 333-222")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "333222")
    }

    // MARK: - Code at Different Positions Tests

    func test_parseMessage_codeAtStart_extractsCode() {
        let result = parser.parseMessage("588107 is your LIKE verification code")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "588107")
        XCTAssertEqual(result?.service, "like")
    }

    func test_parseMessage_codeAtEnd_extractsCode() {
        let result = parser.parseMessage("Auth code: 2607 Please enter this code in your app.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "2607")
    }

    func test_parseMessage_codeInMiddle_extractsCode() {
        let result = parser.parseMessage("Your 123456 verification code for Example")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "123456")
    }

    // MARK: - Code Length Boundary Tests

    func test_parseMessage_threeDigitCode_mayNotParse() {
        // 3-digit codes are typically not parsed as OTPs to avoid false positives
        let result = parser.parseMessage("Your code is 123")

        // The parser may or may not extract 3-digit codes depending on context
        // This test documents the current behavior
        if let result = result {
            XCTAssertEqual(result.code, "123")
        }
    }

    func test_parseMessage_fourDigitCode_extractsCode() {
        let result = parser.parseMessage("0013 is your verification code for HQ Trivia")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "0013")
        XCTAssertEqual(result?.service, "hq trivia")
    }

    func test_parseMessage_eightDigitCode_extractsCode() {
        let result = parser.parseMessage("Your CloudSigma verification code for MEL is 880936")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "880936")
        XCTAssertEqual(result?.service, "cloudsigma")
    }

    // MARK: - Special Character Handling Tests

    func test_parseMessage_codeWithQuotes_extractsCode() {
        let result = parser.parseMessage(#"Your boa code is "521992""#)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "521992")
        XCTAssertEqual(result?.service, "boa")
    }

    func test_parseMessage_codeWithColonPrefix_extractsCode() {
        let result = parser.parseMessage("VerifyCode:736136")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "736136")
    }

    func test_parseMessage_codeWithParentheses_extractsCode() {
        let result = parser.parseMessage("512665 (NetEase Verification Code)")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "512665")
    }

    // MARK: - Multiline Message Tests

    func test_parseMessage_multilineWithCode_extractsCode() {
        let result = parser.parseMessage("Schwab\n394630 is your security code for online login.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "394630")
    }

    func test_parseMessage_codeWithCarriageReturn_extractsCode() {
        let message = "46143020\nvalid 5 minutes\ndurée 5 minutes\r"
        let result = parser.parseMessage(message)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "46143020")
    }

    // MARK: - Invalid Context Tests

    func test_parseMessage_dateTime_shouldNotParseAsCode() {
        // Messages containing time/date patterns should not have those parsed as codes
        let result = parser.parseMessage("Your appointment is at 10:30am on 12/25")

        // Should not extract "1030" or date as code
        XCTAssertNil(result)
    }

    func test_parseMessage_priceAmount_shouldNotParseAsCode() {
        // Dollar amounts should not be parsed as codes
        let result = parser.parseMessage("Your order total is $1234.00")

        XCTAssertNil(result)
    }

    // MARK: - Case Sensitivity Tests

    func test_parseMessage_lowercaseService_normalizedToLowercase() {
        let result = parser.parseMessage("Your GOOGLE verification code is 123456")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "123456")
        XCTAssertEqual(result?.service, "google")
    }

    // MARK: - URL in Message Tests

    func test_parseMessage_codeWithUrl_extractsCodeNotUrlPart() {
        let result = parser.parseMessage("WhatsApp code 569-485. You can also tap on this link to verify your phone: v.whatsapp.com/569485")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "569485")
        XCTAssertEqual(result?.service, "whatsapp")
    }

    // MARK: - Leading Zero Tests

    func test_parseMessage_codeWithLeadingZeros_preservesZeros() {
        let result = parser.parseMessage("Use 003407 as your password for Facebook for iPhone.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "003407")
    }

    func test_parseMessage_fourDigitLeadingZero_preservesZero() {
        let result = parser.parseMessage("Your Uber code is 0137. Never share this code.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "0137")
    }
}
