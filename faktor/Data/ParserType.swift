import Foundation

enum ParserType: String, Codable {
    case offline
    case ai
    
    var displayName: String {
        switch self {
        case .offline:
            return "Faktor Offline"
        case .ai:
            return "Faktor AI"
        }
    }
    
    var description: String {
        switch self {
        case .offline:
            return "Parse codes locally using predefined patterns"
        case .ai:
            return "Use AI to intelligently extract codes (requires internet)"
        }
    }
} 
