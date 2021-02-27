import Foundation

/// 'Buy then Sell' operation consisting in buying then selling at a higher price.
class TraderBTSBuyOperation: CustomStringConvertible {    
    let uuid: String = UUID().uuidString.truncate(length: 5)
    var stopLossPrice: Double = 0
    var updateWhenBelowPrice: Double = 0
    
    var description: String {
        return "BuyOperation \(uuid). Will buy when price > \(stopLossPrice), update when price < updateWhenBelowPrice"
    }
}
