import Foundation

// IDEE

// Vendre quand plus bas, puis racheter si threshold 0.99 atteint ou 102.
// Pareil achat


final class SimpleTrader: MarketDataStreamSubscriber {
    
    private struct Parameters {
        ///The initial limit set at which the limits will be updated
        static let initialUpperLimitPercent = 1.0
        
        static let sellLowerLimitDivisor = 4.0
        
        /// How much does it need to grow so that we update the lower limit at which we should sell due to decrease of price
        static let updateSellUpperLimitPercent: Percent = 0.35
        
        /// How much lower can be the price at which we sell to take the profits in case the price goes down again.
        static let maxSellLowerLimitPercent: Percent = 0.7
        
        /// Minimum lower limit compared to initial price at which we sell.
        static let minLowerLimitPercent: Percent = 0.25
        
        static let minDistancePercentNegative: Percent = -1.0
        static let minDistancePercentPositive: Percent = 0.7

        
        static let prepareBuyOverPricePercent: Percent = 0.5
        static let updatePrepareBuyOverPricePercent: Percent = 0.5
    }
    

    
    let marketAnalyzer = MarketPerSecondHistory(intervalToKeep: TimeInterval.fromHours(2.01))
    var api : MarketDataStream
    
    var orderSize: Double = 25
    
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
    
    init(api: MarketDataStream) {
        balance = initialBalance
        self.api = api
        self.api.subscriber = self
        api.subscribeToAggregatedTradeStream()
    }

    
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
    // ================================================================

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
    
    func buy(price: Double) {

        balance -= orderSize

        let qty = (orderSize / price) -% fees
        let order = TradingOrder(price: price, amount: qty, cost: orderSize)
        self.orders.append(order)
        self.lastBuyOrder = order
        
        order.upperLimit = price +% Percent(Parameters.initialUpperLimitPercent)
        order.lowLimit = price -% Percent(100)

        sourcePrint("[Trade] At \(DateFactory.now) Bought \(qty) for \(price). Cost: \(orderSize)")
    }

    func rebuy(order: TradingOrder, at price: Double) {
        order.intermediateBuy(quantityBought: (order.value / price) -% fees, at: price)
    }

    func intermediateSell(order: TradingOrder, at price: Double) {
        order.intermediateSell(at: price, for: (price * order.quantity) -% fees)
    }
    
    
    
    // MARK: - Decision making
    // ================================================================
    
    private var prepareBuyOverPrice: Double?
    private var locked = false

    func decideNewBuy(price: Double) {
        /// There are always sufficient found here!
        /// There are 2h of statistic availables
        
        
        // Locking
        if locked {
            
            if self.marketAnalyzer.prices(last: TimeInterval.fromHours(1)).isTrendDownwards(threshold: 0.2) {
                return
            }
            
            locked = false
        }
        
        // Buy prepared
        if let prepareBuyOverPrice = self.prepareBuyOverPrice {
            
            if price >= prepareBuyOverPrice {
                buy(price: price)
                self.prepareBuyOverPrice = nil
                return
            }
            
            if price < prepareBuyOverPrice -% Parameters.updatePrepareBuyOverPricePercent {
                prepareBuy(currentPrice: price)
                return
            }
            return
        }
             
        // Device for a buy prep
        if let closestOrder = self.closestOrder(to: price) {
            
            if price == closestOrder.price {
                return
            }
            
            // If case of a decrease, it must be large enough to consider bying again
            if price < closestOrder.price && Percent(differenceOf: price, from: closestOrder.initialPrice) > Parameters.minDistancePercentNegative {
                return
            }
            
            // Same when increasing, but less
            if price > closestOrder.price && Percent(differenceOf: price, from: closestOrder.initialPrice) < Parameters.minDistancePercentPositive {
                return
            }
            
            let lastBuyOrderPrice = lastBuyOrder!.initialPrice
            
            
            if lastBuyOrderPrice < price {
                // Compared to last buy, the price went up.
                
                if Percent(differenceOf: price, from: lastBuyOrderPrice) > Percent(Parameters.initialUpperLimitPercent) {
                    buy(price: price)
                    return
                }
            }
            else {
                                
                // Compared to last buy, the price went down.
                if orders.filter({$0.price > price && DateFactory.now - $0.date < TimeInterval.fromHours(2) }).count >= 2 && marketAnalyzer.prices(last: TimeInterval.fromHours(2)).isTrendDownwards(threshold: 0.2) {
                    // We pause for 3h or 3%
                    self.locked = true
                }
                
                if let lastOpenPrice = orders.last?.price {
                    if Percent(differenceOf: price, from: lastOpenPrice) < 2.0 {
                        prepareBuy(currentPrice: price)
                        return
                    }
                }
                
                // Big drop in short time => we jump on it!
                if Percent(differenceOf: price, from: lastBuyOrderPrice) < Percent(-2) && DateFactory.now - lastBuyOrder!.date < TimeInterval.fromMinutes(5) {
                    prepareBuy(currentPrice: price)
                    return
                }
                // Small slow decrease
                if Percent(differenceOf: price, from: lastBuyOrderPrice) < Percent(-1) && DateFactory.now - lastBuyOrder!.date > TimeInterval.fromMinutes(60) {
                    prepareBuy(currentPrice: price)
                    return
                }
                
                // We sold and the price went down. So we buy again
                guard let lastClosedOrder = closedOrders.last else { return }
                guard let lastOpenedOrderPrice = orders.last?.price else { return }
                
                if price < lastClosedOrder.price && lastOpenedOrderPrice > lastClosedOrder.price {
                    prepareBuy(currentPrice: price)
                }
            }
            
            return
        }
        
        prepareBuy(currentPrice: price)
    }
    
    private func prepareBuy(currentPrice: Double) {
        prepareBuyOverPrice = currentPrice +% Parameters.prepareBuyOverPricePercent
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
                if lowLimitPercentDrop < Parameters.minLowerLimitPercent + 0.1 {
                    return
                }
                
                order.upperLimit = price +% Parameters.updateSellUpperLimitPercent
                order.lowLimit = price -% lowLimitPercentDrop
                return
            }
            
            // If the price goes below the lower limit, but is higher than the original price, we close
            if price < order.lowLimit && Percent(differenceOf: price, from: order.initialPrice) > Parameters.minLowerLimitPercent {
                closeSell(order: order, at: price)
            }
            
            return
        }
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
        sourcePrint("Profits: \(profits) (\(Percent(ratioOf: profits, to: initialBalance).percentage) %) / Per day: \(profits / (timeInterval / 3600 / 24))")
        
        
        sourcePrint("Total assets value: \(currentValue + balance)")
    }
    
    private func printCurrentOrders() {
        for order in self.orders.sorted(by: {$0.initialPrice < $1.initialPrice}) {
            sourcePrint(order.description())
        }
    }
}

