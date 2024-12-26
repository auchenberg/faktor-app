import Foundation
import OSLog

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(code: Int, message: String)
    case decodingError(String)
    case invalidContent
}

struct APIClient {
    private var logger = Logger.core
    private let baseURL: String
    
    init(baseURL: String = "http://localhost:3000") {
        self.logger = Logger.core
        self.baseURL = baseURL
    }
    
    func post<Request: Encodable, Response: Decodable>(
        to endpoint: String,
        body: Request
    ) async throws -> Response {
        logger.info("APIClient.post: Starting request to \(endpoint)")
        
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            logger.error("APIClient.post: Invalid URL")
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            logger.debug("APIClient.post: Request payload prepared")
        } catch {
            logger.error("APIClient.post: Failed to encode request - \(error.localizedDescription)")
            throw APIError.decodingError("Failed to encode request: \(error.localizedDescription)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("APIClient.post: Response is not HTTPURLResponse")
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "No error message"
            logger.error("APIClient.post: HTTP error \(httpResponse.statusCode) - \(errorMessage)")
            throw APIError.httpError(code: httpResponse.statusCode, message: errorMessage)
        }
        
        do {
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            logger.info("APIClient.post: Successfully decoded response")
            return decoded
        } catch {
            logger.error("APIClient.post: Failed to decode response - \(error.localizedDescription)")
            throw APIError.decodingError("Failed to decode response: \(error.localizedDescription)")
        }
    }
} 
