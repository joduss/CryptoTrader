import Foundation

public enum OrderType: CustomStringConvertible {
    case limit
    case market
    case stopLoss
    case stopLossLimit
    case takeProfit
    case takeProfitLimit
    case limitMaker
    
    public var description: String {
        switch self {
        case .limit:
            return "limit"
        case .market:
            return "market"
        case .stopLoss:
            return "stop-loss"
        case .stopLossLimit:
            return "stop-loss-limit"
        case .takeProfit:
            return "take-profit"
        case .takeProfitLimit:
            return "take-profit-limit"
        case .limitMaker:
            return "limit-maker"
        }
    }
}
