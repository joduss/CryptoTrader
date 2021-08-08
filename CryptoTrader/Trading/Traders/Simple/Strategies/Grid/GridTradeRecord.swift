import Foundation

struct GridTradeRecord: Codable {
    
    var date: Date

    var qty: Double
    
    var buyPrice: Double
    var buyValue: Double
    
    var sellPrice: Double
    var sellValue: Double
    
    var profit: Double {
        return sellValue - buyValue
    }
    
    var profitPercent: Percent {
        return Percent(differenceOf: sellValue, from: buyValue)
    }
}
