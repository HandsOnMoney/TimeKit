import Foundation

enum TimeError: LocalizedError {
    case generic(description: String)

    var errorDescription: String? {
        switch self {
        case .generic(let description):
            description
        }
    }
}
