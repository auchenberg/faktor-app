//
//  OTPParserInternationalTests.swift
//  FaktorTests
//
//  Tests for OTP parsing in non-English messages
//

import XCTest
@testable import Faktor

final class OTPParserInternationalTests: XCTestCase {

    var parser: OTPParser!

    override func setUp() {
        super.setUp()
        parser = OTPParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Czech Language Tests

    func test_parseMessage_czech_jtBankaCode_extractsCode() {
        let result = parser.parseMessage("J&T BANKA: Vas autentizacni kod pro prihlaseni do aplikace ePortal je: 7708-5790")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "7708-5790")
        XCTAssertEqual(result?.service, "J&T BANKA")
    }

    func test_parseMessage_czech_spartaIdCode_extractsAlphanumericCode() {
        let result = parser.parseMessage("Vas overovaci kod do SPARTA iD je RW9X0E.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "RW9X0E")
        XCTAssertEqual(result?.service, "SPARTA")
    }

    func test_parseMessage_czech_partnersPortal_extractsCode() {
        let result = parser.parseMessage("Prihlasovaci kod na portal http://moje.partners.cz: ragepr Platnost kodu: 10 minut")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "ragepr")
        XCTAssertEqual(result?.service, "moje.partners.cz")
    }

    // MARK: - Russian Language Tests

    func test_parseMessage_russian_passwordMessage_extractsCode() {
        let result = parser.parseMessage("Пароль: 1752 (никому не говорите) Доступ к информации")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "1752")
    }

    // MARK: - Spanish Language Tests

    func test_parseMessage_spanish_googleCode_extractsCode() {
        let result = parser.parseMessage("Su código de verificación para tu cuenta de Google es 1234567890.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "1234567890")
        XCTAssertEqual(result?.service, "google")
    }

    // MARK: - French Language Tests

    func test_parseMessage_french_googleCode_extractsCode() {
        let result = parser.parseMessage("Votre code de vérification pour votre compte Google est 1234567890.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "1234567890")
        XCTAssertEqual(result?.service, "google")
    }

    // MARK: - German Language Tests

    func test_parseMessage_german_googleCode_extractsCode() {
        let result = parser.parseMessage("Ihr Code für die Google-Konten-Verifizierung ist 1234567890.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "1234567890")
        XCTAssertEqual(result?.service, "google")
    }

    func test_parseMessage_german_sonyCode_extractsCode() {
        let result = parser.parseMessage("117740 ist dein Verifizierungscode für dein Sony Entertainment Network-Konto.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "117740")
        XCTAssertEqual(result?.service, "sony")
    }

    // MARK: - Italian Language Tests

    func test_parseMessage_italian_googleCode_extractsCode() {
        let result = parser.parseMessage("Il codice di verifica per il tuo account Google è 1234567890.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "1234567890")
        XCTAssertEqual(result?.service, "google")
    }

    // MARK: - Korean Language Tests

    func test_parseMessage_korean_googleCode_extractsCode() {
        let result = parser.parseMessage("G-723210(이)가 Google 인증 코드입니다.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "G-723210")
        XCTAssertEqual(result?.service, "google")
    }

    // MARK: - Japanese Language Tests

    func test_parseMessage_japanese_cashShowCode_extractsCode() {
        let result = parser.parseMessage("Cash Show - 賞金クイズ の確認コードは 764972 です。")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "764972")
        XCTAssertEqual(result?.service, "Cash Show")
    }

    // MARK: - Vietnamese Language Tests

    func test_parseMessage_vietnamese_zaloCode_extractsCode() {
        let result = parser.parseMessage("(Zalo) 8568 la ma kich hoat cua so dien thoai 13658014095. Vui long nhap ma nay vao ung dung Zalo de kich hoat tai khoan.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "8568")
        XCTAssertEqual(result?.service, "zalo")
    }

    // MARK: - Chinese Service Tests

    func test_parseMessage_chinese_weiboCode_extractsCode() {
        let result = parser.parseMessage("373473(Weibo login verification code) This code is for user authentication, please do not send it to anyone else.")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "373473")
        XCTAssertEqual(result?.service, "weibo")
    }

    func test_parseMessage_chinese_zcoolCode_extractsCode() {
        let result = parser.parseMessage("[zcool]Your verification code is 991533")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "991533")
        XCTAssertEqual(result?.service, "zcool")
    }

    func test_parseMessage_chinese_wechatCode_extractsCode() {
        let result = parser.parseMessage("Use the code (7744) on WeChat to log in to your account. Don't forward the code!")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.code, "7744")
        XCTAssertEqual(result?.service, "wechat")
    }
}
