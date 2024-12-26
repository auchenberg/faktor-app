import Foundation

struct ParsedOTP: Codable {
    let service: String
    let code: String
    
    init(service: String, code: String) {
        self.service = service
        self.code = code
    }
} 