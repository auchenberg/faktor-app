import Foundation

enum DiskAccessState {
    case needsPermission
    case hasPermission
    case staleBookmark
    case diskAccessDenied
    case databaseNotFound
    case hasDiskAccess
    case error(String)
    
    var requiresAction: Bool {
        switch self {
        case .hasDiskAccess:
            return false
        default:
            return true
        }
    }
    
    var displayMessage: String {
        switch self {
        case .needsPermission:
            return "Disk permissions required"
        case .hasPermission:
            return "Disk permissions granted"
        case .diskAccessDenied:
            return "Disk permissions denied"
        case .staleBookmark:
            return "Disk permissions needs update"
        case .databaseNotFound:
            return "Could not read from database"
        case .hasDiskAccess:
            return "Disk access is working"
        case .error(let message):
            return "Error: \(message)"
        }
    }
} 
