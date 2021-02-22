import Foundation


class SimpleTraderBTSStrategy: SimpleTraderStrategy {
    
    private let config: SimpleTraderStrategyConfiguration
    private let marketAnalyzer: MarketPerSecondHistory = MarketPerSecondHistory(intervalToKeep: TimeInterval.fromHours(6))
    private let symbol: CryptoSymbol
    
    private var currentBalance: Double {
        didSet {
            print("CB: \(currentBalance)")
        }
    }
    private let initialBalance: Double
    private var profits: Double = 0
    
    private var currentBidPrice: Double = 0
    private var currentAskPrice: Double = 0

    private var openBTSBuyOperation: TraderBTSBuyOperation?
    private var openBTSSellOperations: [TraderBTSSellOperation] = []
    private var closedBTSSellOperations: [TraderBTSSellOperation] = []

    private var orderValue: Double = 0
    private var exchange: ExchangeClient
    
    private var locked = false
    
    private var lastBuyPrice: Double? {
        return lastBuyOrder?.initialTrade.price
    }
    
    private var lastBuyOrder: TraderBTSSellOperation? {
        return openBTSSellOperations.sorted(by: {$0.initialTrade.date < $1.initialTrade.date}).last
    }
    
    private var lastClosedOperation: TraderBTSSellOperation? {
        return closedBTSSellOperations.last
    }
    
    
    init(exchange: ExchangeClient, config: SimpleTraderStrategyConfiguration, initialBalance: Double, currentBalance: Double) {
        self.config = config
        self.exchange = exchange
        self.symbol = exchange.symbol
        self.currentBalance = currentBalance
        self.initialBalance = initialBalance
        self.orderValue = initialBalance / Double(config.maxOrdersCount)
    }
    
    
    // ================================================================
    // MARK: - Order update
    // ================================================================

    func update(report: OrderExecutionReport) {
//        if (report.side == .buy) {
//            guard let buyOperation = self.openBTSBuyOperation else { return }
////            buyOperation.update(report)
//
//            switch buyOperation.status {
//            case .new:
//                return
//            case .partiallyFilled:
//                addNewSellOperation(report: report)
//                break
//            case .filled:
//                addNewSellOperation(report: report)
//                self.openBTSBuyOperation = nil
//                break
//            case .cancelled:
//                self.openBTSBuyOperation = nil
//                break
//            case .rejected:
//                self.openBTSBuyOperation = nil
//                break
//            case .expired:
//                self.openBTSBuyOperation = nil
//                break
//            }
//        }
//        else {
//            guard let matchingOperationIndex = openBTSSellOperations.firstIndex(where: { $0.sellOrder?.id == report.clientOrderId }) else {
//                print("Strange, no matching operation found")
//                return
//            }
//
//            let matchingOperation = openBTSSellOperations[matchingOperationIndex]
//
//            matchingOperation.update(report)
//
//            switch matchingOperation.status {
//            case .new:
//                return
//            case .partiallyFilled:
//                currentBalance += report.lastQuoteAssetExecutedQuantity
//                print("Sell Operation partially filled. Balance updated.")
//                break
//                // Nothing
//            case .filled:
//                profits += matchingOperation.profits
//                print("Order \(matchingOperation.sellOrder!) has been filled.")
//                print("\t Total Profits: \(profits)")
//                currentBalance += report.lastQuoteAssetExecutedQuantity
//                closedBTSSellOperations.append(matchingOperation)
//                openBTSSellOperations.remove(at: matchingOperationIndex)
//                break
//            case .cancelled:
//                print("Order \(matchingOperation.sellOrder!) has been cancelled")
//                closedBTSSellOperations.append(matchingOperation)
//                break
//            case .rejected:
//                print("Order \(matchingOperation.sellOrder!) has been cancelled")
//                closedBTSSellOperations.append(matchingOperation)
//                break
//            case .expired:
//                print("Order \(matchingOperation.sellOrder!) has been cancelled")
//                self.openBTSBuyOperation = nil
//                break
//            }
//        }
    }

    
    // ================================================================
    // MARK: - Decisions
    // ================================================================
    
    
    // MARK: Decision about buying
    // ================================================================

    func updateAsk(price: Double) {
        /// There are always sufficient found here!
        /// There are 2h of statistic availables
        /// We usually want to create order "STOP-LOSS BUY", which we update if the price continues to go down,
        /// at least if there is a clear downward trend.
        
        self.currentAskPrice = price
        marketAnalyzer.record(DatedPrice(price: price, date: DateFactory.now))
        
        if openBTSBuyOperation == nil && currentBalance < orderValue {
            return
        }
        
        // Locking
        if locked {
            
            if self.marketAnalyzer.prices(last: TimeInterval.fromHours(1)).isTrendDownwards(threshold: 0.2) {
                return
            }
            
            locked = false
        }
        
        // Buy prepared
        if let buyOperation = self.openBTSBuyOperation {
            // If the price is higher than the buyOperation, then the operation should be executed anytime soon.
            // else, we plan a buy if the price goes up again.
            if price <= buyOperation.updateWhenBelowPrice {
                // Cancel then recreate
                self.updateBuyOperation()
                return
            }
            else if price >= buyOperation.stopLossPrice {
                buy(buyOperation)
            }
            else {
                // nothing
            }
            return
        }
             
        // Decide for a buy prep
        if let closestOrder = self.closestOrder(to: price) {
            
            if price == closestOrder.initialTrade.price {
                return
            }
            
            // If case of a decrease, it must be large enough to consider bying again
            if price < closestOrder.initialTrade.price && Percent(differenceOf: price, from: closestOrder.initialTrade.price) > config.minDistancePercentNegative {
                return
            }
            
            // Same when increasing, but less
            if price > closestOrder.initialTrade.price && Percent(differenceOf: price, from: closestOrder.initialTrade.price) < config.minDistancePercentPositive {
                return
            }
            
            
            guard let lastBuyOrderPrice = lastBuyPrice else {
                sourcePrint("DEBUG: This should be investigated: 'guard let lastBuyOrderPrice = lastBuyPrice!' was false")
                return
            }
            
            if lastBuyOrderPrice < price {
                // Compared to last buy, the price went quite up.
                // We want to buy and see what will happen. Hopefully stil going up to we can sell at a even higher price
                if Percent(differenceOf: price, from: lastBuyOrderPrice) > Percent(config.buyNextBuyOrderPercent) {
                    updateBuyOperation()
                    return
                }
            }
            else {
                // Compared to last buy, the price went down.
                if openBTSSellOperations.filter({$0.initialTrade.price > price && DateFactory.now - $0.initialTrade.date < TimeInterval.fromHours(2) }).count >= 2 && marketAnalyzer.prices(last: TimeInterval.fromHours(2)).isTrendDownwards(threshold: 0.2) {
                    // We pause for 2h or 3%
                    self.locked = true
                    return
                }
                
                if let lastOpenPrice = openBTSSellOperations.last?.initialTrade.price {
                    if Percent(differenceOf: price, from: lastOpenPrice) < 2.0 {
                        updateBuyOperation()
                        return
                    }
                }
                
                // Big drop in short time => we jump on it!
                if Percent(differenceOf: price, from: lastBuyOrderPrice) < Percent(-2) && DateFactory.now - lastBuyOrder!.initialTrade.date < TimeInterval.fromMinutes(5) {
                    updateBuyOperation()
                    return
                }
                // Small slow decrease
                if Percent(differenceOf: price, from: lastBuyOrderPrice) < Percent(-1) && DateFactory.now - lastBuyOrder!.initialTrade.date > TimeInterval.fromMinutes(60) {
                    updateBuyOperation()
                    return
                }
                
                // We sold and the price went down. So we buy again
                guard let lastClosedOrderPrice = lastClosedOperation?.initialTrade.price else { return }
                guard let lastOpenedOrderPrice = lastBuyPrice else { return }
                
                if price < lastClosedOrderPrice && lastOpenedOrderPrice > lastClosedOrderPrice {
                    updateBuyOperation()
                    return
                }
            }
            
            updateBuyOperation()
            return
        }
        
        updateBuyOperation()
    }
    
    private func updateBuyOperation() {
        guard let buyOperation = self.openBTSBuyOperation else {
            self.openBTSBuyOperation = TraderBTSBuyOperation()
            updateBuyOperation()
            return
        }
        
        let buyPrice = currentBidPrice +% config.buyStopLossPercent
        let updatePrice = currentBidPrice -% config.buyUpdateStopLossPercent
        
        buyOperation.stopLossPrice = buyPrice
        buyOperation.updateWhenBelowPrice = updatePrice
        
        print("Updated buy operation \(buyOperation.uuid). Will buy if price > \(buyOperation.stopLossPrice) /update SLP if price < \(buyOperation.updateWhenBelowPrice).")
    }
    
    private func buy(_ operation: TraderBTSBuyOperation) {
        let idGenerator = TraderBTSIdGenerator(id: operation.uuid,
                                               date: DateFactory.now,
                                               action: "BUY", price: currentAskPrice)
        
        let order = TradeOrderRequest.marketBuy(symbol: symbol,
                                                value: orderValue,
                                                id: idGenerator.generate())
        
        let semaphore = DispatchSemaphore(value: 0)
        exchange.trading.send(order: order, completion: { result in
          
            switch result {
                case let .failure(error):
                    sourcePrint(error.localizedDescription)
                case let .success(order):
                    self.openBTSBuyOperation = nil
                    let trade = TraderBTSTrade(price: order.price, quantity: order.originalQty, value: order.cummulativeQuoteQty)
                    self.currentBalance -= order.cummulativeQuoteQty
                    self.openBTSSellOperations.append(TraderBTSSellOperation(trade: trade))
                    sourcePrint("Successfully bought \(order.originalQty)@\(order.price) (\(order.status)")
                    
                    if order.type == .market && order.status != .filled {
                        sourcePrint("ERROR => market order not filled yet!!!")
                    }
                    
            }
            
            semaphore.signal()
        })
        
        semaphore.wait()
    }
     
    
    // MARK: Decisiong about selling
    // =================================================================
    
    
    func updateBid(price: Double) {
        self.currentBidPrice = price
        
        for operation in openBTSSellOperations {
            update(operation: operation, price: price)
        }
    }
    
    private func update(operation: TraderBTSSellOperation, price: Double) {
        
        // If the operation has not sell order associated, we
        // check if an order can be made.
        // Otherwise, we update the order if necessary
        if operation.stopLossPrice == 0 {
            createStopLoss(operation: operation, price: price)
        }
        else if price <= operation.stopLossPrice {
            sell(operation: operation)
        }
        else if (price > operation.updateWhenAbovePrice) {
            createStopLoss(operation: operation, price: price)
        }
        
        // Otherwise, we don't update, the price isn't gone up enough for that.
    }
    
    func createStopLoss(operation: TraderBTSSellOperation, price: Double) {
        
        // If the price is higher than the upper limit, we update the stop-loss sell price.
        
        var lowLimitPercentDrop: Percent = Percent(differenceOf: price, from: operation.initialTrade.price) / config.sellLowerLimitDivisor
        
        if lowLimitPercentDrop > config.sellStopLossProfitPercent {
            lowLimitPercentDrop = config.sellStopLossProfitPercent
        }
        if lowLimitPercentDrop < config.sellMinProfitPercent + 0.1 {
            return
        }
                
        operation.stopLossPrice = price -% lowLimitPercentDrop
        operation.updateWhenAbovePrice = price +% config.sellUpdateStopLossProfitPercent
        
        print("Updated sell operation \(operation.uuid). Will sell if price > \(operation.stopLossPrice) /update SLP if price > \(operation.updateWhenAbovePrice).")

    }
    
    func sell(operation: TraderBTSSellOperation) {
        let orderId = TraderBTSIdGenerator(id: operation.uuid, date: DateFactory.now, action: "SELL", price: currentBidPrice)
        let order = TradeOrderRequest.marketSell(symbol: symbol, qty: operation.initialTrade.quantity, id: orderId.generate())
        
        let semaphore = DispatchSemaphore(value: 0)
        
        exchange.trading.send(order: order, completion: { result in
            switch (result) {
                case let .failure(error):
                    sourcePrint("Failed to create the order \(order) on the exchange for the operation \(operation). (\(error)")
                    break
                case let .success(order):
                    if order.status != .filled {
                        sourcePrint("ERROR: market order NOT FILLED!!!")
                    }
                    operation.closing(with: TraderBTSTrade(price: order.price, quantity: order.originalQty, value: order.cummulativeQuoteQty))
                    sourcePrint("Sold the operation \(operation.description)")
                    self.openBTSSellOperations.remove(operation)
                    self.closedBTSSellOperations.append(operation)
                    
                    self.orderValue += operation.profits / Double(self.config.maxOrdersCount)
                    self.currentBalance += order.cummulativeQuoteQty
                    self.profits += operation.profits
            }
            semaphore.signal()
        })
        semaphore.wait()
    }
    
    
    // MARK: - Helpers
    // =================================================================

    private func closestOrder(to price: Double) -> TraderBTSSellOperation? {
        var diff = Double.greatestFiniteMagnitude
        var closest: TraderBTSSellOperation?
        
        for otherOrder in self.openBTSSellOperations {
            let currentDiff = abs(otherOrder.initialTrade.price - price)
            if currentDiff < diff {
                diff = currentDiff
                closest = otherOrder
            }
        }
        
        return closest
    }
    
    func summary() {
        let currentPrice = marketAnalyzer.prices(last: TimeInterval.fromMinutes(1)).average()
        let coins: Double = openBTSSellOperations.reduce(0.0, {result, newItem in return result + (newItem.initialTrade.quantity)})
        
        print("========================= ")
        print("Trading history")
        print("========================= ")
        
        if let openBuy = self.openBTSBuyOperation {
            print("\nOpen buy operation")
            print("\n-----------")
            print(openBuy.description)
        }
        
        print("\nExecuted operations.")
        print("\n-----------")
        for closeOrder in self.closedBTSSellOperations {
            print(closeOrder.description(currentPrice: currentPrice))
            print("---")
        }
        
        print("\n\n\n----------------------")
        print("Open sell orders")
        print("\n-----------")
        
        for closeOrder in self.openBTSSellOperations {
            print(closeOrder.description(currentPrice: currentPrice))
            print("---")
        }
        
        let firstOrder = closedBTSSellOperations.sorted(by: {$0.initialTrade.date < $1.initialTrade.date}).first!
        let timeInterval = DateFactory.now - firstOrder.initialTrade.date
        
        print("========================= ")
        print("Summary")
        print("========================= \n")
        
        print("Duration: \(timeInterval / 3600 / 24) days \n\n")
        print("Current balance: \(currentBalance)")
        print("Coins: \(coins) @ \(currentPrice)")
        print("Profits: \(profits) (\(Percent(ratioOf: profits, to: initialBalance).percentage) %) / Per day: \(profits / (timeInterval / 3600 / 24))")
        
        
        print("Total assets value: \(coins * currentPrice + currentBalance) / Initial value: \(initialBalance)")
    }
    
    private func printCurrentOrders() {
        for order in self.openBTSSellOperations.sorted(by: {$0.initialTrade.price < $1.initialTrade.price}) {
            sourcePrint(order.description(currentPrice: currentBidPrice))
        }
    }
    
    private func roundPrice(_ price: Double) -> Double {
        return round(price * 100) / 100.0
    }
    
    private func roundQty(_ qty: Double) -> Double {
        return round(qty * 10e5) / 10e5
    }
}
