import Foundation

final class GridMarketPosition: Codable {
        
    var open: Bool {
        return qty > 0
    }
    
    var openable: Bool = false
    
    var targetPriceBottom: Double
    
    var qty: Double = 0
    var price: Double = 0
    var value: Double = 0
    
    var stopLoss: Double = 0
    var openDate: Date?
    
    func sell(at sellPrice: Double, value sellValue: Double, date: Date) -> GridTradeRecord {
        let record = GridTradeRecord(date: date, qty: qty, buyPrice: price, buyValue: value, sellPrice: sellPrice, sellValue: sellValue)
        
        qty = 0
        price = 0
        value = 0
        stopLoss = 0
        openable = false
        openDate = nil

        return record
    }
    
    init(targetPriceBottom: Double) {
        self.targetPriceBottom = targetPriceBottom
    }
}
