import Foundation


class SimpleTraderBTSStrategy: SimpleTraderStrategy {
    
    private let config: SimpleTraderStrategyConfiguration
    private let marketAnalyzer: MarketPerSecondHistory = MarketPerSecondHistory(intervalToKeep: TimeInterval.fromHours(6))
    private let symbol: CryptoSymbol
    
    private var currentBalance: Double
    private var initialBalance: Double
    private var profits: Double = 0
    
    private var currentBidPrice: Double = 0
    private var currentAskPrice: Double = 0

    private var openBTSBuyOperation: TraderBTSBuyOperation?
    private var openBTSSellOperations: [TraderBTSSellOperation] = []
    private var closedBTSSellOperations: [TraderBTSSellOperation] = []

    private var quantityToBuy: Double = 0
    private let exchange: BinanceClient! = nil
    
    private var locked = false
    
    private let semaphore = DispatchSemaphore(value: 1)
    
    
    private var lastBuyPrice: Double? {
        return lastBuyOrder?.trade.price
    }
    
    private var lastBuyOrder: TraderBTSSellOperation? {
        return openBTSSellOperations.sorted(by: {$0.trade.date < $1.trade.date}).last
    }
    
    private var lastClosedOperation: TraderBTSSellOperation? {
        return closedBTSSellOperations.last
    }
    
    
    init(symbol: CryptoSymbol, config: SimpleTraderStrategyConfiguration, initialBalance: Double, currentBalance: Double) {
        self.config = config
        self.symbol = symbol
        self.currentBalance = currentBalance
        self.initialBalance = initialBalance
    }
    
    
    // ================================================================
    // MARK: - Order update
    // ================================================================

    func update(report: OrderExecutionReport) {
        
        semaphore.wait()
        
        defer {
            semaphore.signal()
        }
        
        if (report.side == .buy) {
            guard let buyOperation = self.openBTSBuyOperation else { return }
            buyOperation.update(report)
            
            switch buyOperation.status {
            case .new:
                return
            case .partiallyFilled:
                addNewSellOperation(report: report)
                break
            case .filled:
                addNewSellOperation(report: report)
                self.openBTSBuyOperation = nil
                break
            case .cancelled:
                self.openBTSBuyOperation = nil
                break
            case .rejected:
                self.openBTSBuyOperation = nil
                break
            case .expired:
                self.openBTSBuyOperation = nil
                break
            }
        }
        else {
            guard let matchingOperationIndex = openBTSSellOperations.firstIndex(where: { $0.sellOrder?.id == report.clientOrderId }) else {
                print("Strange, no matching operation found")
                return
            }
            
            let matchingOperation = openBTSSellOperations[matchingOperationIndex]
            
            matchingOperation.update(report)
            
            switch matchingOperation.status {
            case .new:
                return
            case .partiallyFilled:
                currentBalance += report.lastQuoteAssetExecutedQuantity
                print("Sell Operation partially filled. Balance updated.")
                break
                // Nothing
            case .filled:
                print("Order \(matchingOperation.sellOrder!) has been filled. ")
                print("\t Profits: ")
                profits += matchingOperation.profits
                currentBalance += report.lastQuoteAssetExecutedQuantity
                closedBTSSellOperations.append(matchingOperation)
                openBTSSellOperations.remove(at: matchingOperationIndex)
                break
            case .cancelled:
                print("Order \(matchingOperation.sellOrder!) has been cancelled")
                closedBTSSellOperations.append(matchingOperation)
                break
            case .rejected:
                print("Order \(matchingOperation.sellOrder!) has been cancelled")
                closedBTSSellOperations.append(matchingOperation)
                break
            case .expired:
                print("Order \(matchingOperation.sellOrder!) has been cancelled")
                self.openBTSBuyOperation = nil
                break
            }
        }
    }
    
    func addNewSellOperation(report: OrderExecutionReport) {
        let trade = TraderBTSTrade(price: report.lastExecutedPrice, quantity: report.lastExecutedQuantity, value: report.cumulativeQuoteAssetQuantity)
        let operation = TraderBTSSellOperation(trade: trade)
        openBTSSellOperations.append(operation)
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
        
        // Locking
        if locked {
            
            if self.marketAnalyzer.prices(last: TimeInterval.fromHours(1)).isTrendDownwards(threshold: 0.2) {
                return
            }
            
            locked = false
        }
        
        // Buy prepared
        if let buyOperation = self.openBTSBuyOperation {
            
            guard let buyPrice = buyOperation.buyOrder.price else {
                return
            }
            
            // If the price is higher than the buyOperation, then the operation should be executed anytime soon.

            // else, we plan a buy if the price goes up again.
            if price < buyPrice -% config.updatePrepareBuyOverPricePercent {
                // Cancel then recreate
                cancel(order: buyOperation.buyOrder, completion: {
                    result in
                    if (result) {
                        self.prepareBuy(currentPrice: price)
                    }
                    else {
                        print("Failed to cancel the order.")
                    }
                })
                return
            }
            return
        }
             
        // Decide for a buy prep
        if let closestOrder = self.closestOrder(to: price) {
            
            if price == closestOrder.trade.price {
                return
            }
            
            // If case of a decrease, it must be large enough to consider bying again
            if price < closestOrder.trade.price && Percent(differenceOf: price, from: closestOrder.trade.price) > config.minDistancePercentNegative {
                return
            }
            
            // Same when increasing, but less
            if price > closestOrder.trade.price && Percent(differenceOf: price, from: closestOrder.trade.price) < config.minDistancePercentPositive {
                return
            }
            
            
            guard let lastBuyOrderPrice = lastBuyPrice else {
                sourcePrint("DEBUG: This should be investigated: 'guard let lastBuyOrderPrice = lastBuyPrice!' was false")
                return
            }
            
            if lastBuyOrderPrice < price {
                // Compared to last buy, the price went quite up.
                // We want to buy and see what will happen. Hopefully stil going up to we can sell at a even higher price
                if Percent(differenceOf: price, from: lastBuyOrderPrice) > Percent(config.initialUpperLimitPercent) {
                    prepareBuy(currentPrice: price)
                    return
                }
            }
            else {
                // Compared to last buy, the price went down.
                if openBTSSellOperations.filter({$0.trade.price > price && DateFactory.now - $0.trade.date < TimeInterval.fromHours(2) }).count >= 2 && marketAnalyzer.prices(last: TimeInterval.fromHours(2)).isTrendDownwards(threshold: 0.2) {
                    // We pause for 2h or 3%
                    self.locked = true
                    return
                }
                
                if let lastOpenPrice = openBTSSellOperations.last?.trade.price {
                    if Percent(differenceOf: price, from: lastOpenPrice) < 2.0 {
                        prepareBuy(currentPrice: price)
                        return
                    }
                }
                
                // Big drop in short time => we jump on it!
                if Percent(differenceOf: price, from: lastBuyOrderPrice) < Percent(-2) && DateFactory.now - lastBuyOrder!.trade.date < TimeInterval.fromMinutes(5) {
                    prepareBuy(currentPrice: price)
                    return
                }
                // Small slow decrease
                if Percent(differenceOf: price, from: lastBuyOrderPrice) < Percent(-1) && DateFactory.now - lastBuyOrder!.trade.date > TimeInterval.fromMinutes(60) {
                    prepareBuy(currentPrice: price)
                    return
                }
                
                // We sold and the price went down. So we buy again
                guard let lastClosedOrderPrice = lastClosedOperation?.trade.price else { return }
                guard let lastOpenedOrderPrice = lastBuyPrice else { return }
                
                if price < lastClosedOrderPrice && lastOpenedOrderPrice > lastClosedOrderPrice {
                    prepareBuy(currentPrice: price)
                    return
                }
            }
            
            prepareBuy(currentPrice: price)
            return
        }
        
        prepareBuy(currentPrice: price)
    }
    
    private func prepareBuy(currentPrice: Double) {
        let buyPrice = currentPrice +% config.prepareBuyOverPricePercent
        
        if let buyOperation = self.openBTSBuyOperation {
            cancel(order: buyOperation.buyOrder, completion: {
                result in
                if (result) {
                    self.openBTSBuyOperation = self.createBuyOrder(price: buyPrice,
                                                          type: .stopLossLimit)
                }
                else {
                    print("Failed to cancel the order.")
                }
            })
        }
        else {
            openBTSBuyOperation = createBuyOrder(price: buyPrice, type: .stopLossLimit)
        }
    }
     
    
    // MARK: Decisiong about selling
    
    func updateBid(price: Double) {
        
        semaphore.wait()
        
        defer {
            semaphore.signal()
        }
        
        self.currentBidPrice = price
        
        for operation in openBTSSellOperations {
            update(operation: operation, price: price)
        }
    }
    
    private func update(operation: TraderBTSSellOperation, price: Double) {
        
        // If the operation has not sell order associated, we
        // check if an order can be made.
        // Otherwise, we update the order if necessary
        if operation.sellOrder != nil {
            updateOrderOf(operation: operation, price: price)
        }
        else {
            createOrderFor(operation: operation, price: price)
        }
    }
    
    func createOrderFor(operation: TraderBTSSellOperation, price: Double) {
        
        guard price > operation.trade.price +% config.updateSellUpperLimitPercent else {
            return
        }
        
        // If the price is higher than the upper limit, we update the limits
        
        var lowLimitPercentDrop: Percent = Percent(differenceOf: price, from: operation.trade.price) / config.sellLowerLimitDivisor
        
        if lowLimitPercentDrop > config.maxSellLowerLimitPercent {
            lowLimitPercentDrop = config.maxSellLowerLimitPercent
        }
        if lowLimitPercentDrop < config.minLowerLimitPercent + 0.1 {
            return
        }
        
        let orderId = "STOP-LOSS-SELL \(OutputDateFormatter.format(date: DateFactory.now))-\(price -% lowLimitPercentDrop)-\(operation.trade.quantity)"
        let order =  TradeOrderRequest.stopLossSell(symbol: symbol,
                                                    qty: operation.trade.quantity,
                                                    price: price -% lowLimitPercentDrop,
                                                    id: orderId)
        operation.sellOrder = order
        return
    }
    
    func updateOrderOf(operation: TraderBTSSellOperation, price: Double) {
        guard let sellOrder = operation.sellOrder else { return }
        guard let operationSellPrice = sellOrder.price else { return }
        
        guard price > operationSellPrice +% config.updateSellUpperLimitPercent else {
            return
        }
        
        cancel(order: sellOrder, completion: {
            result in
            
            if (result) {
                operation.sellOrder = nil
                self.createOrderFor(operation: operation, price: price)
//                openBTSSellOperations.removeAll(where: {$0 === operation})
            }
            else {
                sourcePrint("Failed to cancel order.")
            }
        })
    }
    
    // MARK: Helpers
    
    private func closestOrder(to price: Double) -> TraderBTSSellOperation? {
        var diff = Double.greatestFiniteMagnitude
        var closest: TraderBTSSellOperation?
        
        for otherOrder in self.openBTSSellOperations {
            let currentDiff = abs(otherOrder.trade.price - price)
            if currentDiff < diff {
                diff = currentDiff
                closest = otherOrder
            }
        }
        
        return closest
    }
    
    func summary() {
        let currentPrice = marketAnalyzer.prices(last: TimeInterval.fromMinutes(1)).average()
        let coins: Double = openBTSSellOperations.reduce(0.0, {result, newItem in return result + (newItem.trade.quantity)})
        
        print("========================= ")
        print("Trading history")
        print("========================= ")
        
        if let openBuy = self.openBTSBuyOperation {
            print("\nOpen buy operation")
            print("\n-----------")
            print(openBuy.description())
        }
        
        sourcePrint("\nExecuted operations.")
        sourcePrint("\n-----------")
        for closeOrder in self.closedBTSSellOperations {
            sourcePrint(closeOrder.description(currentPrice: currentPrice))
            sourcePrint("---")
        }
        
        sourcePrint("\n\n\n----------------------")
        sourcePrint("Open sell orders")
        sourcePrint("\n-----------")
        
        for closeOrder in self.openBTSSellOperations {
            sourcePrint(closeOrder.description(currentPrice: currentPrice))
            sourcePrint("---")
        }
        
        let firstOrder = closedBTSSellOperations.sorted(by: {$0.trade.date < $1.trade.date}).first!
        let timeInterval = DateFactory.now - firstOrder.trade.date
        
        sourcePrint("========================= ")
        sourcePrint("Summary")
        sourcePrint("========================= \n")
        
        sourcePrint("Duration: \(timeInterval / 3600 / 24) days \n\n")
        sourcePrint("Current balance: \(currentBalance)")
        sourcePrint("Coins: \(coins) @ \(currentPrice)")
        sourcePrint("Profits: \(profits) (\(Percent(ratioOf: profits, to: initialBalance).percentage) %) / Per day: \(profits / (timeInterval / 3600 / 24))")
        
        
        sourcePrint("Total assets value: \(coins * currentPrice + currentBalance) / Initial value: \(initialBalance)")
    }
    
    private func printCurrentOrders() {
        for order in self.openBTSSellOperations.sorted(by: {$0.trade.price < $1.trade.price}) {
            sourcePrint(order.description(currentPrice: currentBidPrice))
        }
    }
    
    private func cancel(order: TradeOrderRequest, completion: @ escaping (Bool) -> ()) {
        self.exchange.trading.cancelOrder(symbol: symbol, id: order.id, completion: {
            result in completion(result)
        })
    }
    
    private func createBuyOrder(price: Double, type: OrderType, qty: Double? = nil) -> TraderBTSBuyOperation {
        let quantity = qty ?? initialBalance / Double(config.maxOrdersCount)
        let order = TradeOrderRequest(symbol: symbol,
                                      quantity: quantity,
                                      price: price,
                                      side: .buy,
                                      type: type,
                                      id: "BUY \(OutputDateFormatter.format(date: DateFactory.now))-\(price)-\(quantity)")
        
        return TraderBTSBuyOperation(buyOrder: order)
    }
}
