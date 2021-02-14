import Foundation

struct BinanceOrderTypeConverter {
    
    static func convert(type: OrderType) -> String {
        switch type {
        case .limit:
            return "LIMIT"
        case .market:
            return "MARKET"
        case .stopLoss:
            return "STOP_LOSS"
        case .stopLossLimit:
            return "STOP_LOSS_LIMIT"
        case .takeProfit:
            return "TAKE_PROFIT"
        case .takeProfitLimit:
            return "TAKE_PROFIT_LIMIT"
        case .limitMaker:
            return "LIMIT_MAKER"
        }
    }
    
    static func convert(value: String) throws -> OrderType {
        switch value {
        case "LIMIT":
            return .limit
        case "MARKET":
            return .market
        case "STOP_LOSS":
            return .stopLoss
        case "STOP_LOSS_LIMIT":
            return .stopLossLimit
        case "TAKE_PROFIT":
            return .takeProfit
        case "TAKE_PROFIT_LIMIT":
            return .takeProfitLimit
        case "LIMIT_MAKER":
            return .limitMaker
        default:
            throw ExchangePlatformError.generalError(message: "The order type \(value) is not supported.")
        }
    }
}
