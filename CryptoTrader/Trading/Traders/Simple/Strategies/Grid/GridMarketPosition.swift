import Foundation

class GridMarketPosition: Codable {
        
    var active: Bool {
        return qty > 0
    }
    
    var targetPriceBottom: Decimal
    
    var qty: Decimal = 0
    var price: Decimal = 0
    var value: Decimal = 0
    
    var profitStopLoss: Decimal = 0
    
    func sell(at sellPrice: Decimal, value sellValue: Decimal, date: Date) -> GridTradeRecord {
        let record = GridTradeRecord(date: date, qty: qty, buyPrice: price, buyValue: value, sellPrice: sellPrice, sellValue: sellValue)
        
        qty = 0
        price = 0
        value = 0
        profitStopLoss = 0

        return record
    }
    
    init(targetPriceBottom: Decimal) {
        self.targetPriceBottom = targetPriceBottom
    }
}
