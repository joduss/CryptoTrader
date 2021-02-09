import Foundation

class TradingOrder {
    
    let date: Date
    
    private(set) var orderState = OrderState.open
    
    var closeDate: Date?
    
    // MARK: Initial values
    private(set) var initialPrice: Double
    private(set) var initialQty: Double
    private(set) var initialValue: Double
    

    // MARK: Current values when different than initial values.
    private (set) var currentPrice: Double?
    
    /// Current value of this order.
    private (set) var currentValue: Double?
    
    /// Current quantity of this order. Might be 0 if sold to limit loss
    private (set) var currentQty: Double?
    
    private var qtyHistory: [Double] = []
    
    
    public var lowLimit: Double
    public var upperLimit: Double
    
    public private(set) var canSell: Bool = false
    public private(set) var canBuy: Bool = false
 
    public var quantity: Double {
        return currentQty ?? initialQty
    }
    
    public var value: Double {
        return currentValue ?? initialValue
    }
    
    /// Price of the last operation
    public var price: Double {
        return currentPrice ?? initialPrice
    }
    
    // MARK: - Constructor
    
    init(price: Double, amount: Double, cost: Double) {
        date = DateFactory.now
        initialPrice = price
        initialQty = amount
        initialValue = cost
        qtyHistory.append(amount)
        canSell = true
        canBuy = false
        lowLimit = price
        upperLimit = price
    }
    
    // MARK: - Computations on current values.
    
    func profitIfSold(at price: Double) -> Double {
        return quantity * price - initialValue
    }
    
    // MARK: - Buy / Sell actions
    
    func closeOrderSelling(at price: Double, forCost value: Double) {
        let profits = value - initialValue
        let profitPercent = Percent(differenceOf: value, from: initialValue)
        
        sourcePrint(
            """
            [Trade] Selling order from the \(date)
                    Bought \(initialQty) @ \(initialPrice).
                    Selling \(quantity) @ \(price). Cost: \(value).
                    Profits of \(profits) (\(profitPercent.percentage) %).
            """)
                
        currentPrice = price
        currentValue = value
        currentQty = 0
        closeDate = DateFactory.now
        
        canSell = false
        canBuy = false
        
        orderState = .closed
    }
    
    func intermediateSell(at price: Double, for cost: Double) {
        
        sourcePrint("[Trade] Intermediate sell of \(quantity) at \(price) for \(cost). It was bought at \(initialPrice) for \(initialValue). Current loss is \(cost - initialValue)")
        
        currentPrice = price
        currentValue = cost
        currentQty = 0
        
        canSell = false
        canBuy = true
    }
    
    func intermediateBuy(quantityBought: Double, at price: Double) {
        
        if price == 37084.9 {
            print("")
        }
        
        let soldAt = self.price
        let soldQty = qtyHistory.last!
        
        currentPrice = price
        currentQty = quantityBought
        qtyHistory.append(quantityBought)
        canSell = true
        canBuy = false

        
        sourcePrint("\n[Trade] Rebuy \(quantityBought) at \(price), after selling \(soldQty) at \(soldAt). Original was \(initialQty) at \(price). Qty gained: \(quantityBought - soldQty). From initial \(quantityBought - initialQty)")
        let provisionalProfitsSellOriginalPrice = (quantityBought * initialPrice - initialValue)
        let provisionalProfitsCurrentPrice = (quantityBought * price - initialValue)
        sourcePrint("[Trade] Provisional profits with original price: \(provisionalProfitsSellOriginalPrice)")
        sourcePrint("[Trade] Provisional profits with current price \(price): \(provisionalProfitsCurrentPrice)\n")
    }
    
    func description(for price: Double) -> String {
        
        if let closeDate = self.closeDate {
            
            let profit = value - initialValue
            let profitPercent = Percent(differenceOf: value, from: initialValue)
            
            return
                """
                Order open the (\(OutputDateFormatter.instance.format(date: date)), closed the \(OutputDateFormatter.instance.format(date: closeDate))
                Initial price: \(initialPrice) / Close price: \(price)
                Initial Quantity: \(initialQty)
                Initial value: \(initialValue) / Close value: \(value)
                Profit: \(profit) (\(profitPercent.percentage)%)
                """
        }
        else {
            return
                """
                Order (\(OutputDateFormatter.instance.format(date: date))
                Initial price: \(initialPrice) / Current price: \(price)
                Initial Quantity: \(initialQty)
                Initial value: \(initialValue) / Current: \(price * quantity)
                Lower / Upper limits: \(lowLimit / upperLimit)
                """
        }
    }
    
    func description() -> String {
        
        if let closeDate = self.closeDate {
            
            let profit = value - initialValue
            let profitPercent = Percent(differenceOf: value, from: initialValue)
            
            return
                """
                Order open the (\(OutputDateFormatter.instance.format(date: date)), closed the \(OutputDateFormatter.instance.format(date: closeDate))
                Initial price: \(initialPrice) / Close price: \(price)
                Initial Quantity: \(initialQty)
                Initial value: \(initialValue) / Close value: \(value)
                Profit: \(profit) (\(profitPercent.percentage)%)
                """
        }
        else {
            return
                """
                Order (\(OutputDateFormatter.instance.format(date: date))
                Initial price: \(initialPrice)
                Initial Quantity: \(initialQty)
                Initial value: \(initialValue)
                Lower / Upper limits: \(lowLimit / upperLimit)
                """
        }
    }
}
