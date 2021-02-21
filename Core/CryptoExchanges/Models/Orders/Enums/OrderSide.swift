import Foundation

enum OrderSide: CustomStringConvertible {
    case sell
    case buy
    
    var description: String {
        switch self {
        case .buy:
            return "buy"
        case .sell:
            return "sell"
        }
    }
}
