//
//  OTPParserTests.swift
//  FaktorTests
//
//  Tests for core OTP parsing functionality
//

import XCTest
@testable import Faktor

final class OTPParserTests: XCTestCase {

    var parser: OTPParser!

    override func setUp() {
        super.setUp()
        parser = OTPParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Google OTP Tests

    func test_parseMessage_googleVerificationCode_extractsCodeAndService() {
        let result = parser.parseMessage("G-412157 is your Google verification code.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "412157")
        XCTAssertEqual(result?.service, "google")
    }

    func test_parseMessage_googleCodePrefix_extractsFullGCode() {
        let result = parser.parseMessage("G-830829")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "G-830829")
        XCTAssertEqual(result?.service, "google")
    }

    func test_parseMessage_googleVoice_extractsCodeAndService() {
        let result = parser.parseMessage("750963 is your Google Voice verification code")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "750963")
        XCTAssertEqual(result?.service, "google voice")
    }

    // MARK: - Standard Code Format Tests

    func test_parseMessage_fourDigitCode_extractsCode() {
        let result = parser.parseMessage("2715")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "2715")
    }

    func test_parseMessage_sixDigitCode_extractsCode() {
        let result = parser.parseMessage("Your confirmation code is 951417. Please enter it in the text field.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "951417")
    }

    func test_parseMessage_eightDigitCode_extractsCode() {
        let result = parser.parseMessage("You requested a secure one-time password to log in to your USCIS Account. Please enter this secure one-time password: 04352398")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "04352398")
        XCTAssertEqual(result?.service, "uscis")
    }

    // MARK: - Dashed Code Format Tests

    func test_parseMessage_dashedCode_removeDashAndExtract() {
        let result = parser.parseMessage("123-456 is your Resy account verification code. This is not a booking confirmation.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "123-456")
        XCTAssertEqual(result?.service, "resy")
    }

    func test_parseMessage_whatsappDashedCode_normalizeAndExtract() {
        let result = parser.parseMessage("WhatsApp code 507-240")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "507240")
        XCTAssertEqual(result?.service, "whatsapp")
    }

    func test_parseMessage_spacedCode_normalizeAndExtract() {
        let result = parser.parseMessage("Hello! Your BuzzSumo verification code is 823 815")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "823815")
        XCTAssertEqual(result?.service, "buzzsumo")
    }

    // MARK: - Alphanumeric Code Tests

    func test_parseMessage_alphanumericCode_extractsCode() {
        let result = parser.parseMessage("Your ExampleApp code is: 123ABC78 FA+9qCX9VSu")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "123ABC78")
        XCTAssertEqual(result?.service, "ExampleApp")
    }

    // MARK: - Popular Service Tests

    func test_parseMessage_amazon_extractsCodeAndService() {
        let result = parser.parseMessage("821957 is your Amazon OTP. Do not share it with anyone.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "821957")
        XCTAssertEqual(result?.service, "amazon")
    }

    func test_parseMessage_microsoft_extractsCodeAndService() {
        let result = parser.parseMessage("Use 5677 as Microsoft account security code")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "5677")
        XCTAssertEqual(result?.service, "microsoft")
    }

    func test_parseMessage_linkedin_extractsCodeAndService() {
        let result = parser.parseMessage("Your LinkedIn verification code is 804706.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "804706")
        XCTAssertEqual(result?.service, "linkedin")
    }

    func test_parseMessage_uber_extractsCodeAndService() {
        let result = parser.parseMessage("[#] Your Uber code: 5934 qlRnn4A1sbt")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "5934")
        XCTAssertEqual(result?.service, "uber")
    }

    func test_parseMessage_facebook_extractsCodeAndService() {
        let result = parser.parseMessage("Use 003407 as your password for Facebook for iPhone.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "003407")
        XCTAssertEqual(result?.service, "facebook")
    }

    func test_parseMessage_twitter_extractsCodeAndService() {
        let result = parser.parseMessage("Your Twitter confirmation coce is 180298")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "180298")
        XCTAssertEqual(result?.service, "twitter")
    }

    func test_parseMessage_snapchat_extractsCodeAndService() {
        let result = parser.parseMessage("Snapchat code: 481489. Do not share it or use it elsewhere!")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "481489")
        XCTAssertEqual(result?.service, "snapchat")
    }

    func test_parseMessage_telegram_extractsCodeAndService() {
        let result = parser.parseMessage("Telegram code 65847")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "65847")
        XCTAssertEqual(result?.service, "telegram")
    }

    func test_parseMessage_whatsapp_extractsCodeAndService() {
        let result = parser.parseMessage("Your WhatsApp code is 105-876 but you can simply tap on this link to verify your device: v.whatsapp.com/105876")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "105876")
        XCTAssertEqual(result?.service, "whatsapp")
    }

    func test_parseMessage_twilio_extractsCodeAndService() {
        let result = parser.parseMessage("Your Twilio verification code is: 9508")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "9508")
        XCTAssertEqual(result?.service, "twilio")
    }

    func test_parseMessage_lyft_extractsCodeAndService() {
        let result = parser.parseMessage("Your Lyft code is 744444")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "744444")
        XCTAssertEqual(result?.service, "lyft")
    }

    func test_parseMessage_postmates_extractsCodeAndService() {
        let result = parser.parseMessage("6635 is your Postmates verification code.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "6635")
        XCTAssertEqual(result?.service, "postmates")
    }

    func test_parseMessage_ebay_extractsCodeAndService() {
        let result = parser.parseMessage("Your one-time eBay pin is 3190")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "3190")
        XCTAssertEqual(result?.service, "ebay")
    }

    // MARK: - Bracket Format Tests

    func test_parseMessage_alibabaGroupBracket_extractsCodeAndService() {
        let result = parser.parseMessage("[Alibaba Group]Your verification code is 797428")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "797428")
        XCTAssertEqual(result?.service, "alibaba group")
    }

    func test_parseMessage_huomaoTVBracket_extractsCodeAndService() {
        let result = parser.parseMessage("[HuomaoTV]code: 456291. Please complete the verification within 5 minutes.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "456291")
        XCTAssertEqual(result?.service, "huomaotv")
    }

    func test_parseMessage_neteaseBracket_extractsCodeAndService() {
        let result = parser.parseMessage("512665 (NetEase Verification Code)")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "512665")
        XCTAssertEqual(result?.service, "netease")
    }

    // MARK: - Financial Services Tests

    func test_parseMessage_schwab_extractsCodeAndService() {
        let result = parser.parseMessage("Schwab\n394630 is your security code for online login. Do not share this code with anyone.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "394630")
        XCTAssertEqual(result?.service, "Schwab")
    }

    func test_parseMessage_intuit_extractsCodeAndService() {
        let result = parser.parseMessage("Your Intuit Code is 097074. Do not share this code.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "097074")
        XCTAssertEqual(result?.service, "Intuit")
    }

    // MARK: - Should Not Parse Tests

    func test_parseMessage_deactivationMessage_returnsNil() {
        let result = parser.parseMessage("2-step verification is now deactivated on your Sony Entertainment Network account.")

        XCTAssertNil(result)
    }

    func test_parseMessage_marketingMessage_returnsNil() {
        let result = parser.parseMessage("Reasy. Set. Get. Your new glasses are ready for pick up at LensCrafters! Stop in any time to see the new you. Questions? 718-858-7036")

        XCTAssertNil(result)
    }
}
