import Foundation

class MacdOperation: Codable, CustomStringConvertible {
    
    var id: String = ""
    
    let openDate: Date
    let openCost: Double
    let openPrice: Double
    
    let quantity: Double
    
    var closeDate: Date?
    var closeCost: Double?
    var closePrice: Double?
    
    var closed: Bool { return closeDate != nil}
    
    var profits: Double? {
        guard let closeCost = self.closeCost else { return nil }
        return closeCost - openCost
    }
    
    init(time: Date, price: Double, quantity: Double, cost: Double) {
        self.openDate = time
        self.openPrice = price
        self.quantity = quantity
        self.openCost = cost
    }
    
    func close(time: Date, price: Double, cost: Double) {
        self.closeDate = time
        self.closePrice = price
        self.closeCost = cost
    }
    
    var description: String {
        
        let df = OutputDateFormatter.instance
        let openDateFormatted = df.format(date: openDate)
        
        if !closed {
            return "\(id) - Open on \(openDateFormatted) - \(quantity)@\(openPrice) = \(openCost)"
        }
        
        
        let closeDateFormatted = df.format(date: closeDate!)
        
        let profitsPercent = Percent(differenceOf: closeCost!, from: openCost)
        let profits = closeCost! - openCost

        return "\(id) - Closed on \(closeDateFormatted). Value: \(openCost) => \(closeCost!) (\(profits), \(profitsPercent)%), Price: \(openPrice) => \(closePrice!). Qty: \(quantity)"
    }
    
    func description(currentPrice: Double) -> String {
        let df = OutputDateFormatter.instance
        let openDateFormatted = df.format(date: openDate)
        
        return "\(id) - Open on \(openDateFormatted) - \(quantity) @ \(openPrice) = \(openCost) - Current profits : \(currentPrice * quantity - openCost) (\(Percent(differenceOf: currentPrice * quantity, from: openCost))%) (fee not taken into account)"
    }
    
    func replace(time: Date, price: Double, quantity: Double, cost: Double) -> (MacdOperation, Double) {
        let profits = price * quantity - openCost
        let replacingOp = MacdOperation(time: time, price: price, quantity: quantity, cost: cost)
        
        return (replacingOp, profits)
    }
}
