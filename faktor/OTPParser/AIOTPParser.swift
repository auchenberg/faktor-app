import Foundation
import OSLog

enum AIOTPParserError: Error {
    case invalidMessage
    case apiError(String)
    case parsingError(String)
    case noCodeFound
}

class AIOTPParser: OTPParserProtocol {
    private let client: APIClient
    private let logger = Logger.core
    
    private struct ExtractCodeRequest: Codable {
        let message: String
    }
    
    private struct ExtractCodeResponse: Codable {
        let code: String?
        let service: String
        
        enum CodingKeys: String, CodingKey {
            case code
            case service
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            code = try container.decodeIfPresent(String.self, forKey: .code)
            service = try container.decode(String.self, forKey: .service)
        }
    }
    
    init() {
        self.client = APIClient(baseURL: "https://getfaktor.com")
        logger.info("AIOTPParser.init: Initialized with API client")
    }
    
    func parseMessage(_ message: String) async throws -> ParsedOTP? {
        guard !message.isEmpty else {
            logger.error("AIOTPParser.parseMessage: Empty message received")
            throw AIOTPParserError.invalidMessage
        }
        
        logger.debug("AIOTPParser.parseMessage: Processing message of length \(message.count)")
        
        do {
            let request = ExtractCodeRequest(message: message)
            let response: ExtractCodeResponse = try await client.post(
                to: "/api/extract-code",
                body: request
            )
            
            guard let code = response.code, !code.isEmpty else {
                logger.info("AIOTPParser.parseMessage: No code found in message")
                return nil
            }
            
            let parsedOTP = ParsedOTP(
                service: response.service,
                code: code
            )
            
            logger.debug("AIOTPParser.parseMessage: Successfully parsed message")
            return parsedOTP
            
        } catch let error as APIError {
            logger.error("AIOTPParser.parseMessage: API error - \(error)")
            throw AIOTPParserError.apiError(error.localizedDescription)
        } catch {
            logger.error("AIOTPParser.parseMessage: Unexpected error - \(error.localizedDescription)")
            throw AIOTPParserError.apiError(error.localizedDescription)
        }
    }
} 
