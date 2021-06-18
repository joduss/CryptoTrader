import Foundation

class TraderBTSStrategy: SimpleTraderStrategy {
    

    // MARK: Configuration
    // -------------------------------
    var saveEnabled = true

    private let saveStateLocation: String

    private let exchange: ExchangeClient

    private let config: TraderBTSStrategyConfig
    private let marketAnalyzer: MarketAggregatedHistory
    
    private let minOrderValue: Decimal = 10.2
    
    private let symbol: CryptoSymbol

    // MARK: State
    // -------------------------------
    private let dateFactory: DateFactory
    private(set) var startDate: Date
    var currentDate: Date { return dateFactory.now }
    
    private var initialBalance: Decimal

    private var currentBalance: Decimal {
        didSet { sourcePrint("Current Balance: \(oldValue.format(decimals: 3)) -> \(currentBalance.format(decimals: 3))") }
    }

    private(set) var profits: Decimal = 0
    var balanceValue: Decimal {
        return currentBalance + openBTSSellOperations.map({$0.initialTrade.quantity}).reduce(0, {result, value in return result + value }) * currentBidPrice
    }

    private var currentBidPrice: Decimal = 0
    private var currentAskPrice: Decimal = 0

    private var openBTSBuyOperation: TraderBTSBuyOperation?
    private var openBTSSellOperations: [TraderBTSSellOperation] = []
    private var closedBTSSellOperations: [TraderBTSSellOperation] = []

    private var orderValue: Decimal {
        if config.maxOrdersCount - openBTSSellOperations.count == 0 {
            return 0
        }
        
        return self.currentBalance / Decimal((config.maxOrdersCount - openBTSSellOperations.count))
    }
    
    var openOrders: Int { return openBTSSellOperations.count }

    private var locked: Date? = nil

    // MARK: Computed properties
    // -------------------------------
    
    private var lastBuyPrice: Decimal? {
        return lastBuyOrder?.initialTrade.price
    }

    private var lastBuyOrder: TraderBTSSellOperation? {
        return openBTSSellOperations.sorted(by: { $0.initialTrade.date < $1.initialTrade.date }).last
    }

    private var lastClosedOperation: TraderBTSSellOperation? {
        return closedBTSSellOperations.last
    }

    
    // MARK: Serialization keys.
    // -------------------------------
    
    enum CodingKeys: CodingKey {
        case savedState
    }

    // ================================================================
    // MARK: - Life Cycle
    // ================================================================

    /// Constructor
    init(
        exchange: ExchangeClient,
        config: TraderBTSStrategyConfig,
        initialBalance: Decimal,
        currentBalance: Decimal,
        saveStateLocation: String,
        dateFactory: DateFactory = DateFactory.init()
    ) {
        self.config = config
        self.exchange = exchange
        self.symbol = exchange.symbol
        self.initialBalance = initialBalance
        self.saveStateLocation = saveStateLocation
        self.currentBalance = currentBalance
        self.dateFactory = dateFactory
        self.startDate = self.dateFactory.now
        
        let maxInterval = max(config.lockCheckTrendInterval, config.unlockCheckTrendInterval)
        
        self.marketAnalyzer =
            MarketAggregatedHistory(intervalToKeep: maxInterval, aggregationPeriod: TimeInterval.fromMinutes(1))
        
        self.restore()

        // Balance update. (Might be more, might be less)
        guard initialBalance != self.initialBalance else {
            return
        }
        let balanceChange = initialBalance - self.initialBalance
        
        guard currentBalance + balanceChange >= 0 else {
            fatalError("The balance cannot be decreased: the current balance would be negative.")
        }
        
        self.initialBalance = initialBalance
        self.currentBalance = self.currentBalance + balanceChange
    }
    
    
    // ================================================================
    // MARK: - Commands
    // ================================================================
    
    func buyNow() {
        if currentBalance > orderValue {
            buy(TraderBTSBuyOperation(currentPrice: currentAskPrice, config: config))
        }
    }
    
    func sellAll(profit: Percent) {
        for sellOperation in openBTSSellOperations {
            let targetPrice = sellOperation.initialTrade.price +% profit
            
            exchange
                .trading
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
        guard saveEnabled else { return }

        sourcePrint("Loading saved state")
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: saveStateLocation))
            let state = try JSONDecoder().decode(TraderBTSSavedState.self, from: data)
            
            openBTSSellOperations = state.openSellOperations
            closedBTSSellOperations = state.closedSellOperations
            currentBalance = state.currentBalance
            initialBalance = state.initialBalance
            profits = state.profits
            startDate = state.startDate
        } catch {
            sourcePrint("Failed to restore the state: \(error)")
        }
        sourcePrint("Loaded saved state")
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

    func updateTicker(bid: Decimal, ask: Decimal) {
        updateBid(price: bid)
        updateAsk(price: ask)
    }
    

    // MARK: Decision about BUY
    // ================================================================
    
    private var lastDip: Date? = nil
    

    private func updateAsk(price: Decimal) {
                
        /// There are always sufficient found here!
        /// There are 2h of statistic availables
        /// We usually want to create order "STOP-LOSS BUY", which we update if the price continues to go down,
        /// at least if there is a clear downward trend.
        guard price != self.currentAskPrice else { return }


        self.currentAskPrice = price
        marketAnalyzer.record(DatedPrice(price: price.doubleValue, date: currentDate))
        
        let closestAboveBuyPrice = self.closestAboveOrder(to: price)?.initialTrade.price
        let closestBelowBuyPrice = self.closestBelowOrder(to: price)?.initialTrade.price
        
        // RULE 1: Special buy when there is a huge dip
        if  openBTSBuyOperation == nil,
            orderValue > 0,
            currentBalance >= orderValue,
            let closestAbove = closestAboveBuyPrice,
            Percent(differenceOf: price, from: closestAbove) < config.minDistancePercentNegative,
            price < marketAnalyzer.prices(last: TimeInterval.fromMinutes(30), before: currentDate - config.dipDropThresholdTime).average() -% config.dipDropThresholdPercent
             {
            self.lastDip = currentDate
            sourcePrint("Special buy preparation of a big drop")
            updateBuyOperation()
        }

        if openBTSBuyOperation == nil && (currentBalance < orderValue ||  currentBalance < 2 * orderValue) {
            return
        }


        // Locking
        // ---------
        if let locked = self.locked {
            guard currentDate - locked > config.lockStrictInterval else { return }

            if self.marketAnalyzer
                .prices(last: config.unlockCheckTrendInterval, before: currentDate)
                .isTrendDownwards(threshold: config.unlockTrendThreshold) {
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
                if notTooCloseBuy(buyPrice: currentAskPrice, closestAboveBuyPrice: closestAboveBuyPrice, closestBelowBuyPrice: closestBelowBuyPrice) == false {
                    return
                }
                
                buy(buyOperation)
            } else {
                // nothing
            }
            return
        }
        

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
        
        // TODO: check diff with and without
        if let abovePrice = closestAboveBuyPrice {
//        if let abovePrice = closestAboveBuyPrice, closestBelowBuyPrice == nil {
            let lastLoosingTrades = openBTSSellOperations.filter({
                op in
                op.initialTrade.price > price && currentDate - op.initialTrade.date < config.lock2LossesInLast
            })
            
            let trendDownwards = {
                () in  return self.marketAnalyzer
                    .prices(last: self.config.lockCheckTrendInterval,
                            before: self.currentDate)
                    .isTrendDownwards(threshold: self.config.lockTrendThreshold)
            }
            
            // Compared to last buy, the price went down.
            if lastLoosingTrades.count >= 2 && trendDownwards() {
                sourcePrint("Locking (price: \(price)")
                self.locked = currentDate
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
                && currentDate - lastBuyOrder!.initialTrade.date < TimeInterval.fromMinutes(5)
            {
                updateBuyOperation()
                return
            }
            
            // Small slow decrease
            if Percent(differenceOf: price, from: abovePrice) < Percent(-1)
                && currentDate - lastBuyOrder!.initialTrade.date > TimeInterval.fromMinutes(60)
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
        guard orderValue > 0 else { return }
        guard currentBalance >= orderValue else { return }
        
        guard let buyOperation = self.openBTSBuyOperation else {
            self.openBTSBuyOperation = TraderBTSBuyOperation(currentPrice: currentAskPrice, config: config)
            updateBuyOperation()
            return
        }
        
        buyOperation.updateStopLoss(newPrice: currentAskPrice)
        sourcePrint(
            "Updated buy operation \(buyOperation.uuid). Will buy if price > \(buyOperation.stopLossPrice.format(decimals: 3)) / update SLP if price < \(buyOperation.updateWhenBelowPrice.format(decimals: 3))."
        )
        saveState()
    }
    
    private func notTooCloseBuy(buyPrice: Decimal, closestAboveBuyPrice: Decimal?, closestBelowBuyPrice: Decimal?) -> Bool {
        
        // Check if the current price is not too close of another order
        // made at a higher price
        if let abovePrice = closestAboveBuyPrice,
           Percent(differenceOf: buyPrice, from: abovePrice) > config.minDistancePercentNegative {
            return false
        }
        
        // Check if the current price is not too close of another order made at a lower price
        if let belowPrice = closestBelowBuyPrice,
           Percent(differenceOf: buyPrice, from: belowPrice) < config.minDistancePercentPositive {
            return false
        }
        
        return true
    }
    
    /// Send a buy order to the exchange platform for the given operation.
    private func buy(_ operation: TraderBTSBuyOperation) {
        
        let idGenerator = TraderBTSIdGenerator(
            id: operation.uuid,
            date: currentDate,
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
                        value: order.cummulativeQuoteQty,
                        now: self.currentDate
                    )
                    self.currentBalance -= order.cummulativeQuoteQty
                    self.openBTSSellOperations.append(TraderBTSSellOperation(trade: trade, now: self.currentDate))
                    sourcePrint("Successfully bought \(order.originalQty.format(decimals: 10))@\(order.price) (\(order.status))")
                }
                semaphore.signal()
            }
        )

        semaphore.wait()
        saveState()
    }


    // MARK: Decisiong about selling
    // =================================================================


    func updateBid(price: Decimal) {
        guard price != self.currentBidPrice else { return }
        
        self.currentBidPrice = price

        for operation in openBTSSellOperations {
            update(operation: operation, price: price)
        }
        saveState()
    }

    
    private func update(operation: TraderBTSSellOperation, price: Decimal) {

        // If the operation has not sell order associated, we
        // check if an order can be made.
        // Otherwise, we update the order if necessary
        if operation.stopLossPrice == 0 {
            createStopLoss(operation: operation, price: price)
        } else if price <= operation.stopLossPrice {
            // We check in case there was a problem and the price is much lower than the stoploss
            // and selling would lead to a loss.
            if Percent(differenceOf: price, from: operation.stopLossPrice) > config.sellMinProfitPercent {
                operation.stopLossPrice = 0
                operation.updateWhenAbovePrice = 0
                return
            }
            
            sell(operation: operation)
            
        } else if price > operation.updateWhenAbovePrice {
            createStopLoss(operation: operation, price: price)
        }
        else {
            // Otherwise, we don't update, the price isn't gone up enough for that.
            return
        }
    }

    func createStopLoss(operation: TraderBTSSellOperation, price: Decimal) {

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

        sourcePrint(
            "Updated sell operation \(operation.uuid). Will sell if price < \(operation.stopLossPrice) /update SLP if price > \(operation.updateWhenAbovePrice)."
        )
    }

    func sell(operation: TraderBTSSellOperation) {
        let orderId = TraderBTSIdGenerator(
            id: operation.uuid,
            date: currentDate,
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
                            value: order.cummulativeQuoteQty,
                            now: self.currentDate
                        )
                    )
                    sourcePrint("Sold the operation \(operation.description)")
                    self.openBTSSellOperations.remove(operation)
                    self.closedBTSSellOperations.append(operation)

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

    private func closestOrder(to price: Decimal) -> TraderBTSSellOperation? {
        var diff = Decimal.greatestFiniteMagnitude
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
    private func closestAboveOrder(to price: Decimal) -> TraderBTSSellOperation? {
        var diff = Decimal.greatestFiniteMagnitude
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
    private func closestBelowOrder(to price: Decimal) -> TraderBTSSellOperation? {
        var diff = Decimal.greatestFiniteMagnitude
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
    
    @discardableResult
    func summary(shouldPrint: Bool = true) -> String {
        let currentPrice = marketAnalyzer.prices(last: TimeInterval.fromMinutes(1), before: currentDate).average()
        let coins: Decimal = openBTSSellOperations.reduce(
            0.0,
            { result, newItem in return result + (newItem.initialTrade.quantity) }
        )
        
        var summaryString = ""

        summaryString += "==========================================\n"
        summaryString += "Trading history\n"
        summaryString += "==========================================\n"

        summaryString += "\nOpen buy operation\n"
        summaryString += "\n----------------------\n"
        
        if let openBuy = self.openBTSBuyOperation {
            summaryString += openBuy.description + "\n"
        }
        
        summaryString += "\nLocked? \(String(describing: locked))\n"

        summaryString += "\n\nExecuted operations.\n"
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

        let runDuration: TimeInterval = currentDate - startDate
        let profitPercent = Percent(ratioOf: profits, to: initialBalance).percentage
        let profitPerDay = (profits / Decimal(runDuration / 3600 / 24))
        let profitPerDayPercent = (profitPercent / Decimal(runDuration / 3600 / 24))

        summaryString += "\n==========================================\n"
        summaryString += "Summary\n"
        summaryString += "==========================================\n\n"

        summaryString += "Strategy type: BTS\n"
        summaryString += "Currency: \(symbol)\n"
        summaryString += "Order value: \(orderValue.format(decimals: 2))\n"
        summaryString += "Current balance: \(currentBalance.format(decimals: 2))\n\n"
        summaryString += "Coins: \(coins) @ \(currentPrice.format(decimals: 2))\n"

        summaryString += "Duration: \((runDuration / 3600 / 24).format(decimals: 2)) days \n\n"
        summaryString += "Profits: \(profits.format(decimals: 4)) (\(profitPercent.format(decimals: 4)) %) / Per day: \(profitPerDay.format(decimals: 4)) (\(profitPerDayPercent.format(decimals: 4))%)\n"


        summaryString += "Total assets value: \((coins * currentPrice + currentBalance).format(decimals: 2)) / Initial value: \(initialBalance.format(decimals: 2))\n"
        
        if shouldPrint {
            print(summaryString)
        }
        
        return summaryString
    }

    // MARK: - Utilities
    
    private func roundPrice(_ price: Decimal) -> Decimal {
        let doublePrice = (price as NSDecimalNumber).doubleValue
        return Decimal(round(doublePrice * 100) / 100.0)
    }

    private func roundQty(_ qty: Decimal) -> Decimal {
        let doubleQty = (qty as NSDecimalNumber).doubleValue
        return Decimal(round(doubleQty * 10e5) / 10e5)
    }
}
