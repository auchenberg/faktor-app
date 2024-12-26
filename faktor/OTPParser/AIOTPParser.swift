import Foundation
import OSLog

enum AIOTPParserError: Error {
    case invalidMessage
    case openAIError(String)
    case parsingError(String)
}

class AIOTPParser: OTPParserProtocol {
    private let client: OpenAIClient
    private let logger = Logger.core
    private let apiKey: String = "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"
    
    // Internal struct to match OpenAI's JSON response
    private struct AIResponse: Codable {
        let code: String
        let service: String
    }
    
    init() {
        self.client = OpenAIClient(apiKey: apiKey)
        logger.info("AIOTPParser.init: Initialized with API key")
    }
    
    func parseMessage(_ message: String) async throws -> ParsedOTP? {
        guard !message.isEmpty else {
            logger.error("AIOTPParser.parseMessage: Empty message received")
            throw AIOTPParserError.invalidMessage
        }
        
        logger.debug("AIOTPParser.parseMessage: Processing message of length \(message.count)")
        
        let messages = [
            OpenAIClient.ChatMessage(
                role: "system",
                content: """
                Extract the 2FA code and provider name from the provided messages. If no valid provider is found return Unknown, and if no code is found return null values.
                """
            ),
            OpenAIClient.ChatMessage(
                role: "user",
                content: message
            )
        ]
        
        let responseFormat = OpenAIClient.ResponseFormat(
            type: "json_schema",
            json_schema: OpenAIClient.ResponseFormatJsonSchema(
                name: "code_response",
                schema: OpenAIClient.Schema(
                    type: "object",
                    properties: [
                        "code": OpenAIClient.Property(type: "string", description: "The 2FA verification code"),
                        "service": OpenAIClient.Property(type: "string", description: "The service or company name")
                    ],
                    required: ["code", "service"]
                )
            )
        )
        
        do {
            logger.debug("AIOTPParser.parseMessage: Sending message to OpenAI")
            let result = try await client.chat(
                messages: messages,
                response_format: responseFormat,
                responseType: AIResponse.self
            )
            
            guard let aiResponse = result else {
                logger.error("AIOTPParser.parseMessage: No valid response from OpenAI")
                throw AIOTPParserError.openAIError("No valid response from OpenAI")
            }

            logger.debug("AIOTPParser.parseMessage: Received response from OpenAI")
            
            // Map AIResponse to ParsedOTP
            let parsedOTP = ParsedOTP(service: aiResponse.service, code: aiResponse.code)
            return parsedOTP
            
        } catch let error as OpenAIError {
            logger.error("AIOTPParser.parseMessage: OpenAI error - \(error)")
            throw AIOTPParserError.openAIError(error.localizedDescription)
        } catch {
            logger.error("AIOTPParser.parseMessage: Unexpected error - \(error.localizedDescription)")
            throw AIOTPParserError.openAIError(error.localizedDescription)
        }
    }
} 
