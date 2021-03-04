import Foundation

class SimpleTraderBTSStrategy: SimpleTraderStrategy {
    
    var saveEnabled = true

    private let config: TraderBTSStrategyConfiguration
    private let marketAnalyzer: MarketAggregatedHistory = MarketAggregatedHistory(
        intervalToKeep: TimeInterval.fromHours(12), aggregationPeriod: TimeInterval.fromMinutes(1)
    )
    private let symbol: CryptoSymbol

    private var initialBalance: Double

    private var currentBalance: Double {
        didSet {
            sourcePrint("Current Balance: \(currentBalance)")
        }
    }

    private var profits: Double = 0

    private var currentBidPrice: Double = 0
    private var currentAskPrice: Double = 0

    private var openBTSBuyOperation: TraderBTSBuyOperation?
    private var openBTSSellOperations: [TraderBTSSellOperation] = []
    private var closedBTSSellOperations: [TraderBTSSellOperation] = []

    private var orderValue: Double = 0
    private var exchange: ExchangeClient

    private var locked: Date? = nil
    
    private let saveStateLocation: String
    
    private var firstTickerDate: Date!


    private var lastBuyPrice: Double? {
        return lastBuyOrder?.initialTrade.price
    }

    private var lastBuyOrder: TraderBTSSellOperation? {
        return openBTSSellOperations.sorted(by: { $0.initialTrade.date < $1.initialTrade.date }).last
    }

    private var lastClosedOperation: TraderBTSSellOperation? {
        return closedBTSSellOperations.last
    }

    enum CodingKeys: CodingKey {
        case savedState
    }

    init(
        exchange: ExchangeClient,
        config: TraderBTSStrategyConfiguration,
        initialBalance: Double,
        currentBalance: Double,
        saveStateLocation: String
    ) {
        self.config = config
        self.exchange = exchange
        self.symbol = exchange.symbol
        self.initialBalance = initialBalance
        self.orderValue = initialBalance / Double(config.maxOrdersCount)
        self.saveStateLocation = saveStateLocation
        self.currentBalance = currentBalance
        
        self.restore()

        // Balance update. (Might be more, might be less)
        guard initialBalance != self.initialBalance else { return }
        let balanceChange = initialBalance - self.initialBalance
        
        guard currentBalance + balanceChange >= 0 else {
            fatalError("The balance cannot be decreased: the current balance would be negative.")
        }
        
        self.initialBalance = initialBalance
        self.currentBalance = self.currentBalance + balanceChange
        self.orderValue = self.orderValue + balanceChange / Double(config.maxOrdersCount)
    }
    
    // ================================================================
    // MARK: - Commands
    // ================================================================
    
    func buyNow() {
        if currentBalance > orderValue {
            buy(TraderBTSBuyOperation())
        }
    }
    
    func sellAll(profit: Percent) {
        for sellOperation in openBTSSellOperations {
            let targetPrice = sellOperation.initialTrade.price +% profit
            
            exchange.trading
                .send(order:
                        TradeOrderRequest
                        .limitSell(symbol: symbol,
                                   qty: sellOperation.initialTrade.quantity,
                                   price: targetPrice,
                                   id: TraderBTSIdGenerator(id: "sell-all",
                                                            date: currentDate,
                                                            action: "sell",
                                                            price: targetPrice)
                                    .generate()),
                      completion: { result in
                        switch result {
                            case let .failure(error):
                                sourcePrint("Failed to create a limit sell. \(error)")
                            default:
                                break
                        }
                      })
        }
    }

    // ================================================================
    // MARK: - State saving
    // ================================================================

    func saveState() {
        guard saveEnabled else { return }
        
        do {
            let state = TraderBTSSavedState(
                openSellOperations: openBTSSellOperations,
                closedSellOperations: closedBTSSellOperations,
                currentBalance: currentBalance,
                initialBalance: initialBalance,
                orderValue: orderValue,
                profits: profits,
                startDate: startDate
            )
            
            let data = try JSONEncoder().encode(state)
            
            try data.write(to: URL(fileURLWithPath: saveStateLocation))
        } catch {
            sourcePrint("Failed to save the state: \(error)")
        }
    }
    
    func restore() {
        sourcePrint("Loading saved state")
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: saveStateLocation))
            let state = try JSONDecoder().decode(TraderBTSSavedState.self, from: data)
            
            openBTSSellOperations = state.openSellOperations
            closedBTSSellOperations = state.closedSellOperations
            currentBalance = state.currentBalance
            initialBalance = state.initialBalance
            orderValue = state.orderValue
            profits = state.profits
            startDate = state.startDate
        } catch {
            sourcePrint("Failed to restore the state: \(error)")
        }
        sourcePrint("Loaded saved state")
        summary()
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
        if firstTickerDate == nil {
            firstTickerDate = DateFactory.now
        }
        /// There are always sufficient found here!
        /// There are 2h of statistic availables
        /// We usually want to create order "STOP-LOSS BUY", which we update if the price continues to go down,
        /// at least if there is a clear downward trend.
        guard price != self.currentAskPrice else { return }


        self.currentAskPrice = price
        marketAnalyzer.record(DatedPrice(price: price, date: DateFactory.now))

        if openBTSBuyOperation == nil && currentBalance < orderValue {
            return
        }
        
        // TODO: Special buy when there is a huge dip
        
        // Try to check if creating a special stop loss sell is helpful.
        if let lastClosedSell = self.lastClosedOperation,
           let lastBuyOrder = self.lastBuyOrder,
           lastBuyOrder.initialTrade.date < lastClosedSell.closingTrade!.date,
           DateFactory.now - lastClosedSell.closingTrade!.date < config.nextBuyTargetExpiration {
        
            if lastClosedSell.closingTrade!.price -% config.nextBuyTargetPercent > price {
                sourcePrint("Buying target price below last sell!")
                buy(TraderBTSBuyOperation())
                return
            }
        }

        // Locking
        if let locked = self.locked {
            guard DateFactory.now - locked > TimeInterval.fromMinutes(5) else { return }

            if self.marketAnalyzer.prices(last: TimeInterval.fromHours(6)).isTrendDownwards(threshold: 0.2) {
                return
            }

            sourcePrint("Unlocking (price: \(price)")
            self.locked = nil
        }

        // Buy prepared
        if let buyOperation = self.openBTSBuyOperation {
            // If the price is higher than the buyOperation, then the operation should be executed anytime soon.
            // else, we plan a buy if the price goes up again.
            if price <= buyOperation.updateWhenBelowPrice {
                // Cancel then recreate
                self.updateBuyOperation()
                return
            } else if price >= buyOperation.stopLossPrice {
                buy(buyOperation)
            } else {
                // nothing
            }
            return
        }
        
        
        let closestAboveBuyPrice = self.closestAboveOrder(to: price)?.initialTrade.price
        let closestBelowBuyPrice = self.closestBelowOrder(to: price)?.initialTrade.price

        if closestAboveBuyPrice == nil && closestBelowBuyPrice == nil {
            updateBuyOperation()
            return
        }
        
        // Check if the current price is not too close of another order
        // made at a higher price
        if let abovePrice = closestAboveBuyPrice,
           Percent(differenceOf: price, from: abovePrice) > config.minDistancePercentNegative {
            return
        }
        
        // Check if the current price is not too close of another order made at a lower price
        if let belowPrice = closestBelowBuyPrice,
           Percent(differenceOf: price, from: belowPrice) < config.minDistancePercentPositive {
            return
        }

        
        if let belowPrice = closestBelowBuyPrice, closestAboveBuyPrice == nil {
            // Compared to last buys, the price went quite up.
            // We want to buy and see what will happen. Hopefully stil going up to we can sell at a even higher price
            if Percent(differenceOf: price, from: belowPrice) > config.minDistancePercentPositive {
                updateBuyOperation()
                return
            }
        }
        
        
        if let abovePrice = closestAboveBuyPrice, closestBelowBuyPrice == nil {
            // Compared to last buy, the price went down.
            if openBTSSellOperations.filter({
                $0.initialTrade.price > price && DateFactory.now - $0.initialTrade.date < TimeInterval.fromHours(12)
            }).count >= 2 && marketAnalyzer.prices(last: TimeInterval.fromHours(2)).isTrendDownwards(threshold: 0.2)
            {
                // We pause for 2h or 3%
                sourcePrint("Locking (price: \(price)")
                self.locked = DateFactory.now
                return
            }
            
            if let lastOpenPrice = openBTSSellOperations.last?.initialTrade.price {
                if Percent(differenceOf: price, from: lastOpenPrice) < 2.0 {
                    updateBuyOperation()
                    return
                }
            }
            
            // Big drop in short time => we jump on it!
            if Percent(differenceOf: price, from: abovePrice) < Percent(-2)
                && DateFactory.now - lastBuyOrder!.initialTrade.date < TimeInterval.fromMinutes(5)
            {
                updateBuyOperation()
                return
            }
            // Small slow decrease
            if Percent(differenceOf: price, from: abovePrice) < Percent(-1)
                && DateFactory.now - lastBuyOrder!.initialTrade.date > TimeInterval.fromMinutes(60)
            {
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
        
        
        // we can still be in the middle
        
        return
    }

    private func updateBuyOperation() {
        guard let buyOperation = self.openBTSBuyOperation else {
            self.openBTSBuyOperation = TraderBTSBuyOperation()
            updateBuyOperation()
            saveState()
            return
        }

        let buyPrice = currentBidPrice +% config.buyStopLossPercent
        let updatePrice = currentBidPrice -% config.buyUpdateStopLossPercent

        buyOperation.stopLossPrice = buyPrice
        buyOperation.updateWhenBelowPrice = updatePrice

        sourcePrint(
            "Updated buy operation \(buyOperation.uuid). Will buy if price > \(buyOperation.stopLossPrice) /update SLP if price < \(buyOperation.updateWhenBelowPrice)."
        )
        saveState()
    }

    private func buy(_ operation: TraderBTSBuyOperation) {
        let idGenerator = TraderBTSIdGenerator(
            id: operation.uuid,
            date: DateFactory.now,
            action: "BUY",
            price: currentAskPrice
        )

        let order = TradeOrderRequest.marketBuy(
            symbol: symbol,
            value: orderValue,
            id: idGenerator.generate()
        )

        let semaphore = DispatchSemaphore(value: 0)
        exchange.trading.send(
            order: order,
            completion: { result in

                switch result {
                case let .failure(error):
                    sourcePrint("The SELL order failed \(error)")
                case let .success(order):
                    if order.type == .market && order.status != .filled {
                        sourcePrint("ERROR => market order not filled yet!!!")
                        return
                    }
                    
                    self.openBTSBuyOperation = nil
                    let trade = TraderBTSTrade(
                        price: order.price,
                        quantity: order.originalQty,
                        value: order.cummulativeQuoteQty
                    )
                    self.currentBalance -= order.cummulativeQuoteQty
                    self.openBTSSellOperations.append(TraderBTSSellOperation(trade: trade))
                    sourcePrint("Successfully bought \(order.originalQty)@\(order.price) (\(order.status))")
                }
                semaphore.signal()
            }
        )

        saveState()
        semaphore.wait()
    }


    // MARK: Decisiong about selling
    // =================================================================


    func updateBid(price: Double) {
        guard price != self.currentBidPrice else { return }
        
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
        } else if price <= operation.stopLossPrice {
            sell(operation: operation)
        } else if price > operation.updateWhenAbovePrice {
            createStopLoss(operation: operation, price: price)
        }
        else {
            // Otherwise, we don't update, the price isn't gone up enough for that.
            return
        }
    }

    func createStopLoss(operation: TraderBTSSellOperation, price: Double) {

        // If the price is higher than the upper limit, we update the stop-loss sell price.
        var stopLossPricePercent: Percent =
            Percent(differenceOf: price, from: operation.initialTrade.price) - config.sellStopLossProfitPercent

        var stopLossProfit = config.sellStopLossProfitPercent
        
        
        if stopLossPricePercent < config.sellMinProfitPercent {
            stopLossPricePercent = Percent(differenceOf: price, from: operation.initialTrade.price) - config.minSellStopLossProfitPercent
            stopLossProfit = config.minSellStopLossProfitPercent
            
            if stopLossPricePercent < config.sellMinProfitPercent {
                return
            }
        }

        operation.stopLossPrice = price -% stopLossProfit
        operation.updateWhenAbovePrice = price +% config.sellUpdateStopLossProfitPercent
        self.saveState()

        sourcePrint(
            "Updated sell operation \(operation.uuid). Will sell if price < \(operation.stopLossPrice) /update SLP if price > \(operation.updateWhenAbovePrice)."
        )

    }

    func sell(operation: TraderBTSSellOperation) {
        let orderId = TraderBTSIdGenerator(
            id: operation.uuid,
            date: DateFactory.now,
            action: "SELL",
            price: currentBidPrice
        )
        let order = TradeOrderRequest.marketSell(
            symbol: symbol,
            qty: operation.initialTrade.quantity,
            id: orderId.generate()
        )

        let semaphore = DispatchSemaphore(value: 0)

        exchange.trading.send(
            order: order,
            completion: { result in
                switch result {
                case let .failure(error):
                    sourcePrint(
                        "Failed to create the order \(order) on the exchange for the operation \(operation). (\(error)"
                    )
                    break
                case let .success(order):
                    if order.status != .filled {
                        sourcePrint("ERROR: market order NOT FILLED!!!")
                    }
                    operation.closing(
                        with: TraderBTSTrade(
                            price: order.price,
                            quantity: order.originalQty,
                            value: order.cummulativeQuoteQty
                        )
                    )
                    sourcePrint("Sold the operation \(operation.description)")
                    self.openBTSSellOperations.remove(operation)
                    self.closedBTSSellOperations.append(operation)

                    self.orderValue += operation.profits / Double(self.config.maxOrdersCount)
                    self.currentBalance += order.cummulativeQuoteQty
                    self.profits += operation.profits
                }
                semaphore.signal()
            }
        )
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

    /// Returns the closest sell operation whose buy price is higher or equal than the current price.
    private func closestAboveOrder(to price: Double) -> TraderBTSSellOperation? {
        var diff = Double.greatestFiniteMagnitude
        var closest: TraderBTSSellOperation?
        
        for otherOrder in self.openBTSSellOperations {
            guard otherOrder.initialTrade.price >= price else { continue }
            
            let currentDiff = abs(otherOrder.initialTrade.price - price)
            if currentDiff < diff {
                diff = currentDiff
                closest = otherOrder
            }
        }
        
        return closest
    }
    
    /// Returns the closest sell operation whose buy price is lower or equal than the current price.
    private func closestBelowOrder(to price: Double) -> TraderBTSSellOperation? {
        var diff = Double.greatestFiniteMagnitude
        var closest: TraderBTSSellOperation?
        
        for otherOrder in self.openBTSSellOperations {
            guard otherOrder.initialTrade.price <= price else { continue }

            let currentDiff = abs(otherOrder.initialTrade.price - price)
            if currentDiff < diff {
                diff = currentDiff
                closest = otherOrder
            }
        }
        
        return closest
    }
    
    
    // MARK: - Information Display
    // =================================================================
    
    func summary() -> String {
        let currentPrice = marketAnalyzer.prices(last: TimeInterval.fromMinutes(1)).average()
        let coins: Double = openBTSSellOperations.reduce(
            0.0,
            { result, newItem in return result + (newItem.initialTrade.quantity) }
        )
        
        var summaryString = ""

        summaryString += "===================================\n"
        summaryString += "Trading history\n"
        summaryString += "===================================\n"

        if let openBuy = self.openBTSBuyOperation {
            summaryString += "\nOpen buy operation\n"
            summaryString += "\n----------------------\n"
            summaryString += openBuy.description + "\n"
        }

        summaryString += "\nExecuted operations.\n"
        summaryString += "\n----------------------\n"
        for closeOrder in self.closedBTSSellOperations {
            summaryString += closeOrder.description + "\n"
            summaryString += "---\n"
        }

        summaryString += "\n\n\n----------------------\n"
        summaryString += "Open sell orders\n"
        summaryString += "\n----------------------\n"

        for closeOrder in self.openBTSSellOperations {
            summaryString += closeOrder.description(currentPrice: currentPrice) + "\n"
            summaryString += "---\n"
        }

        let runDuration: TimeInterval = DateFactory.now - firstTickerDate
        let profitPercent = Percent(ratioOf: profits, to: initialBalance).percentage
        let profitPerDay = (profits / (runDuration / 3600 / 24))
        let profitPerDayPercent = (profitPercent / (runDuration / 3600 / 24))

        summaryString += "===================================\n"
        summaryString += "Summary\n"
        summaryString += "===================================\n\n"

        summaryString += "Duration: \(runDuration / 3600 / 24) days \n\n\n"
        summaryString += "Current balance: \(currentBalance.format(decimals: 2))\n"
        summaryString += "Coins: \(coins) @ \(currentPrice.format(decimals: 2))\n"
        summaryString += "Profits: \(profits.format(decimals: 4)) (\(profitPercent.format(decimals: 4)) %) / Per day: \(profitPerDay.format(decimals: 4)) (\(profitPerDayPercent.format(decimals: 4))%)\n"


        summaryString += "Total assets value: \((coins * currentPrice + currentBalance).format(decimals: 2)) / Initial value: \(initialBalance)\n"
        
        print(summaryString)
        return summaryString
    }

    // MARK: - Utilities
    
    private func roundPrice(_ price: Double) -> Double {
        return round(price * 100) / 100.0
    }

    private func roundQty(_ qty: Double) -> Double {
        return round(qty * 10e5) / 10e5
    }
}
