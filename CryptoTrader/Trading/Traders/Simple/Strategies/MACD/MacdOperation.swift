import Foundation

class MacdOperation: Codable, CustomStringConvertible {
    
    var id: String = ""
    
    let openDate: Date
    let openCost: Decimal
    let openPrice: Decimal
    
    let quantity: Decimal
    
    var closeDate: Date?
    var closeCost: Decimal?
    var closePrice: Decimal?
    
    var closed: Bool { return closeDate != nil}
    
    var profits: Decimal? {
        guard let closeCost = self.closeCost else { return nil }
        return closeCost - openCost
    }
    
    init(time: Date, price: Decimal, quantity: Decimal, cost: Decimal) {
        self.openDate = time
        self.openPrice = price
        self.quantity = quantity
        self.openCost = cost
    }
    
    func close(time: Date, price: Decimal, cost: Decimal) {
        self.closeDate = time
        self.closePrice = price
        self.closeCost = cost
    }
    
    var description: String {
        
        let df = OutputDateFormatter.instance
        let openDateFormatted = df.format(date: openDate)
        
        if !closed {
            return "\(id) - Open on \(openDateFormatted) - \(quantity) @ \(openPrice) = \(openCost)"
        }
        
        
        let closeDateFormatted = df.format(date: closeDate!)
        
        let profitsPercent = Percent(differenceOf: closeCost!, from: openCost)
        let profits = closeCost! - openCost

        return "\(id) - Closed on \(closeDateFormatted). Value: \(openCost) => \(closeCost!) (\(profits), \(profitsPercent)%), Price: \(openPrice) => \(closePrice!). Qty: \(quantity)"
    }
    
    func description(currentPrice: Decimal) -> String {
        let df = OutputDateFormatter.instance
        let openDateFormatted = df.format(date: openDate)
        
        return "\(id) - Open on \(openDateFormatted) - \(quantity) @ \(openPrice) = \(openCost) - Current profits : \(currentPrice * quantity - openCost) (\(Percent(differenceOf: currentPrice * quantity, from: openCost))%) (fee not taken into account)"
    }
    
    func replace(time: Date, price: Decimal, quantity: Decimal, cost: Decimal) -> (MacdOperation, Decimal) {
        let profits = price * quantity - openCost
        let replacingOp = MacdOperation(time: time, price: price, quantity: quantity, cost: cost)
        
        return (replacingOp, profits)
    }
}
