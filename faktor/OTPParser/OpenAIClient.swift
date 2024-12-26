import Foundation
import OSLog

enum OpenAIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(code: Int, message: String)
    case decodingError(String)
    case invalidContent
    case jsonParsingError(String)
}

struct OpenAIClient {
    private let apiKey: String
    private let logger = Logger.core
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let store: Bool
        let messages: [ChatMessage]
        let response_format: ResponseFormat
        
        init(messages: [ChatMessage], model: String = "gpt-4o-mini", response_format: ResponseFormat) {
            self.model = model
            self.messages = messages
            self.store = true
            self.response_format = response_format
        }
    }
    
    struct ResponseFormat: Codable {
        let type: String
        let json_schema: ResponseFormatJsonSchema
    }
    
    struct ResponseFormatJsonSchema: Codable {
        let name: String
        let schema: Schema
    }
    
    struct Schema: Codable {
        let type: String
        let properties: [String: Property]
        let required: [String]
    }
    
    struct Property: Codable {
        let type: String
        let description: String
    }
    
    struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String?
            }
            let message: Message
        }
        let choices: [Choice]
    }
    
    func chat<T: Codable>(
        messages: [ChatMessage], 
        response_format: ResponseFormat,
        responseType: T.Type
    ) async throws -> T? {
        logger.info("OpenAIClient.chat: Starting request with \(messages.count) messages")
        
        guard let url = URL(string: endpoint) else {
            logger.error("OpenAIClient.chat: Invalid endpoint URL")
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatRequest = ChatRequest(messages: messages, response_format: response_format)
        
        do {
            request.httpBody = try JSONEncoder().encode(chatRequest)
            logger.debug("OpenAIClient.chat: Request payload prepared")
        } catch {
            logger.error("OpenAIClient.chat: Failed to encode request - \(error.localizedDescription)")
            throw OpenAIError.decodingError("Failed to encode request: \(error.localizedDescription)")
        }
        
        logger.info("OpenAIClient.chat: Sending request to OpenAI")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("OpenAIClient.chat: Response is not HTTPURLResponse")
            throw OpenAIError.invalidResponse
        }
        
        logger.debug("OpenAIClient.chat: Received response with status code \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
            logger.error("OpenAIClient.chat: HTTP error \(httpResponse.statusCode) - \(errorMessage)")
            throw OpenAIError.httpError(code: httpResponse.statusCode, message: errorMessage)
        }
        
        let chatResponse: ChatResponse
        do {
            chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            logger.debug("OpenAIClient.chat: Successfully decoded response")
        } catch {
            logger.error("OpenAIClient.chat: Failed to decode response - \(error.localizedDescription)")
            throw OpenAIError.decodingError("Failed to decode response: \(error.localizedDescription)")
        }
        
        guard let content = chatResponse.choices.first?.message.content else {
            logger.error("OpenAIClient.chat: No content in response")
            throw OpenAIError.invalidContent
        }
        
        guard let jsonData = content.data(using: .utf8) else {
            logger.error("OpenAIClient.chat: Failed to convert content to data")
            throw OpenAIError.jsonParsingError("Failed to convert content to data")
        }
        
        do {
            let result = try JSONDecoder().decode(T.self, from: jsonData)
            logger.info("OpenAIClient.chat: Successfully decoded response to type \(T.self)")
            return result
        } catch {
            logger.error("OpenAIClient.chat: Failed to parse JSON content - \(error.localizedDescription)")
            throw OpenAIError.jsonParsingError("Failed to parse JSON: \(error.localizedDescription)")
        }
    }
} 
