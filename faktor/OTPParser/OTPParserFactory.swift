import Foundation

class OTPParserFactory {
    static func createParser() -> OTPParserProtocol {
        return OTPParser()
    }
}

protocol OTPParserProtocol {
    func parseMessage(_ message: String) async throws -> ParsedOTP?
}
