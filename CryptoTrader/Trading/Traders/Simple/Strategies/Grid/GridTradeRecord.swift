import Foundation

struct GridTradeRecord: Codable {
    
    var date: Date

    var qty: Decimal
    
    var buyPrice: Decimal
    var buyValue: Decimal
    
    var sellPrice: Decimal
    var sellValue: Decimal
    
    var profit: Decimal {
        return sellValue - buyValue
    }
    
    var profitPercent: Percent {
        return Percent(differenceOf: sellValue, from: buyValue)
    }
}
