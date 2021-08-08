import Foundation

class GridMarketPosition: Codable {
        
    var active: Bool {
        return qty > 0
    }
    
    var targetPriceBottom: Double
    
    var qty: Double = 0
    var price: Double = 0
    var value: Double = 0
    
    var profitStopLoss: Double = 0
    
    func sell(at sellPrice: Double, value sellValue: Double, date: Date) -> GridTradeRecord {
        let record = GridTradeRecord(date: date, qty: qty, buyPrice: price, buyValue: value, sellPrice: sellPrice, sellValue: sellValue)
        
        qty = 0
        price = 0
        value = 0
        profitStopLoss = 0

        return record
    }
    
    init(targetPriceBottom: Double) {
        self.targetPriceBottom = targetPriceBottom
    }
}
