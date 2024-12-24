import Foundation
import OSLog

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
    
    struct Function: Codable {
        let name: String
        let description: String
        let parameters: Parameters
        
        struct Parameters: Codable {
            let type: String
            let properties: [String: Property]
            let required: [String]
        }
        
        struct Property: Codable {
            let type: String
            let description: String
        }
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let functions: [Function]
        let function_call: String
        let temperature: Double
        
        init(messages: [ChatMessage], model: String = "gpt-4o-mini") {
            self.messages = messages
            self.model = model
            self.temperature = 0.7
            self.functions = [
                Function(
                    name: "extract_2fa_code",
                    description: "Extract 2FA code and provider from message",
                    parameters: Function.Parameters(
                        type: "object",
                        properties: [
                            "code": Function.Property(
                                type: "string",
                                description: "The 2FA verification code"
                            ),
                            "provider_name": Function.Property(
                                type: "string",
                                description: "The name of the service or provider sending the code"
                            )
                        ],
                        required: ["code", "provider_name"]
                    )
                )
            ]
            self.function_call = "{ \"name\": \"extract_2fa_code\" }"
        }
    }
    
    struct ChatResponse: Codable {
        struct Choice: Codable {
            struct Message: Codable {
                let content: String?
                let function_call: FunctionCall?
                
                struct FunctionCall: Codable {
                    let name: String
                    let arguments: String
                }
            }
            let message: Message
        }
        let choices: [Choice]
    }
    
    struct ExtractedOTP: Codable {
        let code: String
        let provider_name: String
    }
    
    func chat(messages: [ChatMessage]) async throws -> ExtractedOTP? {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatRequest = ChatRequest(messages: messages)
        request.httpBody = try JSONEncoder().encode(chatRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("OpenAIClient.chat: Invalid response type")
            return nil
        }
        
        guard httpResponse.statusCode == 200 else {
            logger.error("OpenAIClient.chat: HTTP error \(httpResponse.statusCode)")
            throw NSError(domain: "OpenAI", code: httpResponse.statusCode)
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        
        guard let functionCall = chatResponse.choices.first?.message.function_call,
              functionCall.name == "extract_2fa_code",
              let argumentData = functionCall.arguments.data(using: .utf8) else {
            logger.error("OpenAIClient.chat: Invalid function call response")
            return nil
        }
        
        return try JSONDecoder().decode(ExtractedOTP.self, from: argumentData)
    }
} 
