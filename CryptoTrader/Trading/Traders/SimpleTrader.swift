import Foundation

// IDEE

// Vendre quand plus bas, puis racheter si threshold 0.99 atteint ou 102.
// Pareil achat


final class SimpleTrader: CryptoExchangePlatformSubscriber {
    
    private struct Parameters {
        static let buyUpperLimitPercent = 1.0
        
        static let sellLowerLimitDivisor = 3.5
        
        /// How much does it need to grow so that we update the lower limit at which we should sell due to decrease of price
        static let sellUpperLimitPercent: Percent = 0.2
        
        /// How much lower can be the price at which we sell to take the profits in case the price goes down again.
        static let maxSellLowerLimitPercent: Percent = 0.6
        
        /// Minimum lower limit compared to initial price at which we sell.
        static let minLowerLimitPercent: Percent = 0.25
    }
    
    // Profits = 13.599324848781983
    //    static let buyUpperLimitPercent = 0.5
    //    static let sellLowerLimitDivisor = 2.5
    //    static let sellLowerLimitPercent = 0.4
    //    static let sellUpperLimitPercent = 0.2
    
    // Profits = 14.640733885920692
    //    private struct Parameters {
    //        static let buyUpperLimitPercent = 0.6
    //        static let sellLowerLimitDivisor = 4
    //        static let sellLowerLimitPercent = 0.5
    //        static let sellUpperLimitPercent = 0.2
    //    }
    
    // Profits = 15.461218620192053
    //    private struct Parameters {
    //        static let buyUpperLimitPercent = 0.6
    //        static let sellLowerLimitDivisor = 5
    //        static let sellLowerLimitPercent = 0.6
    //        static let sellUpperLimitPercent = 0.2
    //    }
    
    let marketAnalyzer = MarketPerSecondHistory(intervalToKeep: TimeInterval.fromHours(2.01))
    var api : CryptoExchangePlatform
    
    var orderSize: Double = 20
    
    let initialBalance = 250.0
    var balance: Double
    
    var orders: [TradingOrder] = []
    
    var lastBuyOrder: TradingOrder?
    var closedOrders: [TradingOrder] = []
    
    var fees = Percent(0.1)
    
    var profits: Double = 0
    
    var hasSufficientBalance: Bool {
        return balance > orderSize
    }
    
    init(api: CryptoExchangePlatform) {
        balance = initialBalance
        self.api = api
        self.api.subscriber = self
        api.subscribeToAggregatedTradeStream()
    }
    
//    private func canBuyAt(price: Double) -> Bool {
//        if hasSufficientBalance == false {
//            return false
//        }
//
//        if Percent(differenceOf: price, from: lowerInitialPrice()) < Percent(1) {
//            return true
//        }
//
//        if Percent(differenceOf: price, from: maxInitialPrice()) > Percent(1) {
//            return true
//        }
//
//        return false
//    }
    
    func process(ticker: MarketTicker) {

    }
    
    func process(trade: MarketAggregatedTrade) {
        marketAnalyzer.record(trade)
        decide(price: trade.price)
    }
    
    func process(depthUpdate: MarketDepth) {
        
    }
    
    private var decisionCount = 0
    
    func decide(price: Double) {
        decisionCount += 1
        
        if decisionCount % 200 == 0 {
            sourcePrint("Decision for price \(price)")
        }
        
        if hasSufficientBalance && marketAnalyzer.hasRecordFromAtLeastPastInterval(TimeInterval.fromHours(2)) {
            decideNewBuy(price: price)
        }
        
        for order in orders {
            
            if order.canBuy {
                decideRebuy(order: order, price: price)
            }
            else if (order.canSell) {
                decideSell(order: order, price: price)
            }
        }
    }
    
    // MARK: - Action of sellin / buying
    
    var lastSell: Double = 0
    var lastSellDate: Date = DateFactory.now

    func closeSell(order: TradingOrder, at price: Double) {
        
        lastSell = price
        lastSellDate = DateFactory.now

        let sellCost = (order.quantity * price) -% fees
        let sellProfits = sellCost - order.initialValue
        order.closeOrderSelling(at: price, forCost: sellCost)
        profits += sellProfits
        balance += sellCost
        
        
        self.orders.removeAll(where: {$0 === order})
        closedOrders.append(order)
        
        sourcePrint("Total Profits: \(profits)")
    }

    func rebuy(order: TradingOrder, at price: Double) {
        order.intermediateBuy(quantityBought: (order.value / price) -% fees, at: price)
    }

    func intermediateSell(order: TradingOrder, at price: Double) {
        order.intermediateSell(at: price, for: (price * order.quantity) -% fees)
    }
    
    
    
    // MARK: - Decision making
    
    func decideNewBuy(price: Double) {
        /// There are always sufficient found here!
        /// There are 2h of statistic availables
                
        if let closestOrder = self.closestOrder(to: price) {
            
            if abs(Percent(differenceOf: price, from: closestOrder.initialPrice).percentage) < 0.25 {
                return
            }
            
            let lastBuyOrderPrice = lastBuyOrder!.initialPrice
            
            
            if lastBuyOrderPrice < price {
                // Compared to last buy, the price went up.
                
                if Percent(differenceOf: price, from: lastBuyOrderPrice) > Percent(Parameters.buyUpperLimitPercent) {
                    buy(price: price)
                    return
                }
            }
            else {
                // Compared to last buy, the price went down.
                
                // Going down... we are carefull, if we buy, we plan small profits
                // TODO
                
                if let lastClosedOrder = closedOrders.last, Percent(differenceOf: price, from: lastClosedOrder.price) > Percent(-0.4) {
                    return
                }
                
                // Big drop in short time => we jump on it!
                if Percent(differenceOf: price, from: lastBuyOrderPrice) < Percent(-3) && DateFactory.now - lastBuyOrder!.date < TimeInterval.fromMinutes(5) {
                    buy(price: price)
                    return
                }
                // Small slow decrease
                if Percent(differenceOf: price, from: lastBuyOrderPrice) < Percent(-1) && DateFactory.now - lastBuyOrder!.date > TimeInterval.fromMinutes(60) {
                    buy(price: price)
                    return
                }
            }
            
            return
        }
        
        buy(price: price)
    }
    
    func decideRebuy(order: TradingOrder, price: Double) { }

    func decideSell(order: TradingOrder, price: Double) {
        
        if price > 3000000 {
            printCurrentOrders()
        }
        
        if price > order.initialPrice {
            
            // If the price is higher than the upper limit, we update the limits
            if price > order.upperLimit {
                
                var lowLimitPercentDrop: Percent = Percent(differenceOf: price, from: order.initialPrice) / Parameters.sellLowerLimitDivisor
                
                if lowLimitPercentDrop >  Parameters.maxSellLowerLimitPercent {
                    lowLimitPercentDrop = Parameters.maxSellLowerLimitPercent
                }
                if lowLimitPercentDrop < Parameters.minLowerLimitPercent {
                    lowLimitPercentDrop = Parameters.minLowerLimitPercent
                }
                
                order.upperLimit = price +% Parameters.sellUpperLimitPercent
                order.lowLimit = price -% lowLimitPercentDrop
                return
            }
            
            // If the price goes below the lower limit, but is higher than the original price, we close
            if price < order.lowLimit {
                closeSell(order: order, at: price)
            }
            
            return
        }
    }

    func buy(price: Double) {

        balance -= orderSize

        let qty = (orderSize / price) -% fees
        let order = TradingOrder(price: price, amount: qty, cost: orderSize)
        self.orders.append(order)
        self.lastBuyOrder = order
        
        order.upperLimit = price +% Percent(Parameters.buyUpperLimitPercent)
        order.lowLimit = price -% Percent(100)

        sourcePrint("[Trade] At \(DateFactory.now) Bought \(qty) for \(price). Cost: \(orderSize)")
    }
    
    private func lowerInitialPrice() -> Double {
        return orders.min(by: {$0.price < $1.price})?.price ?? Double.greatestFiniteMagnitude
    }
    
    private func maxInitialPrice() -> Double {
        return orders.max(by: {$0.price < $1.price})?.price ?? Double.greatestFiniteMagnitude
    }
    
    private func closestOrder(to price: Double) -> TradingOrder? {
        var diff = Double.greatestFiniteMagnitude
        var closest: TradingOrder?
        
        for otherOrder in self.orders {
            let currentDiff = abs(otherOrder.initialPrice - price)
            if currentDiff < diff {
                diff = currentDiff
                closest = otherOrder
            }
        }
        
        return closest
    }

    func summary() {
        let currentPrice = marketAnalyzer.prices(last: TimeInterval.fromMinutes(1)).average()
        let coins: Double = orders.reduce(0.0, {result, newItem in return result + (newItem.currentQty ?? 0.0)})
        
        sourcePrint("========================= ")
        sourcePrint("Trading history")
        sourcePrint("========================= ")
        
        sourcePrint("\nClosed orders")
        sourcePrint("\n-----------")
        for closeOrder in self.closedOrders {
            sourcePrint(closeOrder.description(for: currentPrice))
            sourcePrint("---")
        }
        
        sourcePrint("\n\n\n----------------------")
        sourcePrint("Open orders")
        sourcePrint("\n-----------")

        var currentValue = 0.0

        for order in orders {
            sourcePrint(order.description(for: currentPrice))
            sourcePrint("---")
            currentValue += (order.quantity) * currentPrice
        }
        
        let firstOrder = closedOrders.sorted(by: {$0.date < $1.date}).first!
        let timeInterval = DateFactory.now - firstOrder.date
        
        sourcePrint("========================= ")
        sourcePrint("Summary")
        sourcePrint("========================= \n")
        
        sourcePrint("Duration: \(timeInterval / 3600 / 24) days \n\n")
        sourcePrint("Current balance: \(balance)")
        sourcePrint("Coins: \(coins) @ \(currentPrice)")
        sourcePrint("Profits: \(profits) (\(Percent(ratioOf: profits, to: initialBalance)) %) / Per day: \(profits / (timeInterval / 3600 / 24))")
        
        
        sourcePrint("Total assets value: \(currentValue + balance)")
    }
    
    private func printCurrentOrders() {
        for order in self.orders.sorted(by: {$0.initialPrice < $1.initialPrice}) {
            sourcePrint(order.description())
        }
    }
}


