import Foundation

struct BinanceOrderSideConverter {
    
    static func convert(_ value: OrderSide) -> String {
        switch value {
        case .sell:
            return "SELL"
        case .buy:
            return "BUY"
        }
    }
    
    static func convert(_ value: String) throws -> OrderSide {
        switch value {
        case "BUY":
            return .buy
        case "SELL":
            return .sell
        default:
            throw TradingPlatformError.generalError(message: "OrderSide \(value) is not supported.")
        }
    }
    
}
