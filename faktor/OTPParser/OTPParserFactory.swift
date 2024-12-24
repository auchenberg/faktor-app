import Foundation
import Defaults
import OSLog

class OTPParserFactory {
    static func createParser() -> OTPParserProtocol {
        Logger.core.info("OTPParserFactory.createParser: Creating parser type=\(Defaults[.settingsUseAIForParsing])")
        
        switch Defaults[.settingsUseAIForParsing] {

            case true:
                Logger.core.info("OTPParserFactory.createParser: Creating AI parser")
                return AIOTPParser()
            default:
                return OTPParser()
        }
    }
    
    static func resetToOffline() {
        Logger.core.info("OTPParserFactory.resetToOffline: Resetting parser to offline mode")
        Defaults[.settingsUseAIForParsing] = false
    }
}

protocol OTPParserProtocol {
    func parseMessage(_ message: String) async throws -> ParsedOTP?
}
