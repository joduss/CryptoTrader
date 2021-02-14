import Foundation

struct BinanceOrderStatusConverter {
    
    static func convert(_ value: OrderStatus) -> String {
        switch value {
        case .new:
            return "NEW"
        case .partiallyFilled:
            return "PARTIALLY_FILLED"
        case .filled:
            return "FILLED"
        case .cancelled:
            return "CANCELED"
        case .rejected:
            return "REJECTED"
        case .expired:
            return "EXPIRED"
        }
    }
    
    static func convert(_ value: String) throws -> OrderStatus {
        switch value {
        case "NEW":
            return .new
        case "PARTIALLY_FILLED":
            return .partiallyFilled
        case "FILLED":
            return .filled
        case "CANCELED":
            return .cancelled
        case "REJECTED":
            return .rejected
        case "EXPIRED":
            return .expired
        default:
            throw ExchangePlatformError.generalError(message: "OrderStatus \(value) is not supported.")
        }
    }
    
}
