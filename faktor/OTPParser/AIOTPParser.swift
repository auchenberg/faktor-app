import Foundation
import OSLog

class AIOTPParser: OTPParserProtocol {
    private let client: OpenAIClient
    private let logger = Logger.core
    private let apiKey: String = "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  "
    
    init() {
        self.client = OpenAIClient(apiKey: apiKey)
    }
    
    func parseMessage(_ message: String) async throws -> ParsedOTP? {
        let messages = [
            OpenAIClient.ChatMessage(
                role: "system",
                content: """
                Extract the 2FA code and the provider name from the given text message.
                Parse the message to identify both the 2FA code and the name of the provider.
                
                # Output Format
                Provide the output in JSON format with the following structure:
                - "code": [extracted code]
                - "provider_name": [extracted provider name]
                """
            ),
            OpenAIClient.ChatMessage(
                role: "user",
                content: "<text>\(message)</text>"
            )
        ]
        
        do {
            guard let response = try await client.chat(messages: messages) else {
                logger.error("AIOTPParser.parseMessage: No response from OpenAI")
                return nil
            }
            
            guard let jsonData = response.data(using: .utf8) else {
                logger.error("AIOTPParser.parseMessage: Failed to convert response to data")
                return nil
            }
            
            struct AIResponse: Codable {
                let code: String?
                let provider_name: String?
            }
            
            let decoder = JSONDecoder()
            guard let parsedResponse = try? decoder.decode(AIResponse.self, from: jsonData),
                  let code = parsedResponse.code,
                  let service = parsedResponse.provider_name else {
                logger.error("AIOTPParser.parseMessage: Failed to decode response")
                return nil
            }
            
            logger.info("AIOTPParser.parseMessage: Successfully parsed message. Service: \(service), Code: \(code)")
            return ParsedOTP(service: service, code: code)
            
        } catch {
            logger.error("AIOTPParser.parseMessage: Error calling OpenAI - \(error.localizedDescription)")
            throw error
        }
    }
} 
