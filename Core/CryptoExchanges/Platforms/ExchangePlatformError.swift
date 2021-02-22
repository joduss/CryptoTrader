import Foundation

enum ExchangePlatformError: Error {
    case parsingError(message: String)
    case error(error: Error)
    case generalError(message: String)
    case orderFailed(message: String)
    
    var errorDescription: String? {
        switch self {
        case let .parsingError(message):
            return message
        case let .error(error: anError):
            return String(describing: anError)
        case let .generalError(message: message):
            return message
        case let .orderFailed(message: message):
            return message
        }
    }
}
