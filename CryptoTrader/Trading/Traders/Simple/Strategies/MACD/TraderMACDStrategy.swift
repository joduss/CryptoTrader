import Foundation
import tulipindicators

class TraderMACDStrategy: SimpleTraderStrategy {
    
    
    // MARK: Configuration
    // -------------------------------
    var saveEnabled = true
    
    private let saveStateLocation: String
    
    private let exchange: ExchangeClient
    
    private let config: TraderMacdStrategyConfig
    private let marketAnalyzer: MarketAggregatedHistory
    
    private let symbol: CryptoSymbol
    
    // MARK: State
    // -------------------------------
    private let dateFactory: DateFactory
    private(set) var startDate: Date
    var currentDate: Date { return dateFactory.now }
    
    private var initialBalance: Double
    
    private var currentBalance: Double {
        didSet { sourcePrint("Current Balance: \(oldValue) -> \(currentBalance)") }
    }
    
    private(set) var profits: Double = 0
    
    private var currentBidPrice: Double = 0
    private var currentAskPrice: Double = 0
    
    private var openOperations: [MacdOperation] = []
    private var closedOperations: [MacdOperation] = []
    
    private var orderValue: Double = 0
    
    private var locked: Date? = nil
    
    
    // MARK: Computed properties
    // -------------------------------
    
    private var lastBuyPrice: Double? {
        return openOperations.last?.openPrice
    }
    
    private var lastBuyOrder: MacdOperation? {
        return openOperations.last
    }
    
    private var lastClosedOperation: MacdOperation? {
        return closedOperations.last
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
        config: TraderMacdStrategyConfig,
        initialBalance: Double,
        currentBalance: Double,
        saveStateLocation: String,
        dateFactory: DateFactory? = nil
    ) {
        self.config = config
        self.exchange = exchange
        self.symbol = exchange.symbol
        self.initialBalance = initialBalance
        self.orderValue = initialBalance / Double(config.maxOrdersCount)
        self.saveStateLocation = saveStateLocation
        self.currentBalance = currentBalance
        self.dateFactory = dateFactory ?? DateFactory.init()
        self.startDate = self.dateFactory.now
        
        let maxInterval = config.macdLong
        
        self.marketAnalyzer =
            MarketAggregatedHistory(intervalToKeep: TimeInterval(maxInterval * 2), aggregationPeriod: TimeInterval.fromMinutes(1))
        
        self.restore()
        
        // Balance update. (Might be more, might be less)
        guard initialBalance != self.initialBalance else { return }
        let balanceChange = initialBalance - self.initialBalance
        
        guard currentBalance + balanceChange >= 0 else {
            fatalError("The balance cannot be decreased: the current balance would be negative.")
        }
        
        self.initialBalance = initialBalance
        self.currentBalance = self.currentBalance + balanceChange
        self.orderValue = self.currentBalance / Double(config.maxOrdersCount - openOperations.count)
    }
    
    
    // ================================================================
    // MARK: - Commands
    // ================================================================
    
    func buyNow() {
        print("Not supported")
        if currentBalance > orderValue {
            buy()
        }
    }
    
    func sellAll(profit: Percent) {
        print("Not supported")

//        for sellOperation in openOperations {
//            let targetPrice = sellOperation.initialTrade.price +% profit
//
//            exchange
//                .trading
//                .send(order:
//                        TradeOrderRequest
//                        .limitSell(symbol: symbol,
//                                   qty: sellOperation.initialTrade.quantity,
//                                   price: targetPrice,
//                                   id: TraderBTSIdGenerator(id: "sell-all",
//                                                            date: currentDate,
//                                                            action: "sell",
//                                                            price: targetPrice)
//                                    .generate()),
//                      completion: { result in
//                        switch result {
//                            case let .failure(error):
//                                sourcePrint("Failed to create a limit sell. \(error)")
//                            default:
//                                break
//                        }
//                      })
//        }
    }
    
    // ================================================================
    // MARK: - State saving
    // ================================================================
    
    func saveState() {
        guard saveEnabled else { return }

        do {
            let state = TraderMACDStrategySavedState(
                openOperations: openOperations,
                closeOperations: closedOperations,
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
            let state = try JSONDecoder().decode(TraderMACDStrategySavedState.self, from: data)

            openOperations = state.openOperations
            closedOperations = state.closeOperations
            currentBalance = state.currentBalance
            initialBalance = state.initialBalance
            orderValue = state.orderValue
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
    
    func update(report: OrderExecutionReport) { }
    
    
    // ================================================================
    // MARK: - Decisions
    // ================================================================
    
    
    // MARK: Decision about BUY
    // ================================================================
    
    private var lastDip: Date? = nil
    
    private var macdStatistic: MACDResult!
    
    /// Called on second
    func updateAsk(price: Double) {
        /// There are always sufficient found here!
        /// There are 2h of statistic availables
        /// We usually want to create order "STOP-LOSS BUY", which we update if the price continues to go down,
        /// at least if there is a clear downward trend.
        guard price != self.currentAskPrice else { return }
        guard marketAnalyzer.prices.count > Int(config.macdLong) else { return }
        
        
        self.currentAskPrice = price
                
        if let closestAbovePrice = self.closestAboveOrder(to: price)?.openPrice,
           Percent(differenceOf: price, from: closestAbovePrice) > config.minDistancePercentBelow {
            return
        }
        
        if let closestBelowPrice = self.closestBelowOrder(to: price)?.openPrice {
            
            let lastLossesCount = self.openOperations.filter({op in op.openPrice > price}).count
            var minDist = config.minDistancePercentAbove

            if lastLossesCount > config.maxOrdersCount {
                minDist = Percent(config.minDistancePercentAbove.percentage * Double(lastLossesCount) / 4)
            }
            
            if Percent(differenceOf: price, from: closestBelowPrice) < minDist {
                return
            }
        }
        
        guard let mcadValue = macdStatistic.macd.last else { return }
        guard let mcadSignal = macdStatistic.signal.last else { return }
        
        if mcadValue < mcadSignal { return }
                
        if buy() {
            sourcePrint("Bought @ \(price) because macd / signal => \(mcadValue) / \(mcadSignal)")
        }
    }
    
    /// Send a buy order to the exchange platform for the given operation.
    private func buy() -> Bool {
        
        if orderValue > currentBalance {
                        
//            let maxOp = openOperations.max(by: {$0.openPrice <= $1.openPrice})!
//            
//            let (replacingOp, loss) = maxOp.replace(time: dateFactory.now,
//                                                    price: currentAskPrice,
//                                                    quantity: maxOp.quantity,
//                                                    cost: maxOp.quantity * currentAskPrice)
//            
//            profits += loss
//
//            openOperations.remove(maxOp)
//            openOperations.append(replacingOp)
//            sourcePrint("Replaced op. Loss: \(loss) \(Percent(maxOp.openCost / maxOp.quantity * currentAskPrice))%")
//            
            return false
        }
                
        let idGenerator = TraderBTSIdGenerator(
            id: String(closedOperations.count + openOperations.count + 1),
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
                        
                        let newOperation = MacdOperation(time: self.currentDate,
                                                         price: order.price,
                                                         quantity: order.originalQty,
                                                         cost: order.cummulativeQuoteQty)
                        newOperation.id = idGenerator.generate()
                        
                        self.openOperations.append(newOperation)
                        
                        self.currentBalance -= order.cummulativeQuoteQty

                        sourcePrint("Successfully bought \(order.originalQty)@\(order.price) (\(order.status))")
                }
                semaphore.signal()
            }
        )
        
        semaphore.wait()
        saveState()
        
        return true
    }
    
    
    // MARK: Decisiong about selling
    // =================================================================
    
    /// Called first.
    func updateBid(price: Double) {
        
        marketAnalyzer.record(DatedPrice(price: price, date: currentDate))

        guard price != self.currentBidPrice else { return }
        guard marketAnalyzer.prices.count > Int(config.macdLong) else { return }
        
        self.currentBidPrice = price
        let (_, macdStatisticUpdate)
            = macd(Array<Double>(marketAnalyzer.prices.map({$0.price})), short: config.macdShort, long: config.macdLong, signal: config.macdSignal)
        
        self.macdStatistic = macdStatisticUpdate
        
        
        guard let mcadValue = macdStatistic.macd.last else { return }
        guard let mcadSignal = macdStatistic.signal.last else { return }
        
        guard mcadValue < mcadSignal else { return }

        
        for operation in openOperations {
            guard (Percent(differenceOf: price, from: operation.openPrice) > config.minProfitsPercent) else {
                continue
            }
            sell(operation: operation)
        }
        saveState()
    }

    
    func sell(operation: MacdOperation) {
        let orderId = TraderBTSIdGenerator(
            id: operation.id,
            date: currentDate,
            action: "SELL",
            price: currentBidPrice
        )
        let order = TradeOrderRequest.marketSell(
            symbol: symbol,
            qty: operation.quantity,
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
                        
                        operation.close(time: self.currentDate, price: order.price, cost: order.cummulativeQuoteQty)
                        
                        sourcePrint("Sold the operation \(operation.description)")
                        self.openOperations.remove(operation)
                        self.closedOperations.append(operation)
                        
                        self.orderValue += operation.profits! / Double(self.config.maxOrdersCount)
                        self.currentBalance += order.cummulativeQuoteQty
                        self.profits += operation.profits!
                }
                semaphore.signal()
            }
        )
        semaphore.wait()
    }
    
    
    // MARK: - Helpers
    // =================================================================
    
    /// Returns the closest sell operation whose buy price is higher or equal than the current price.
    private func closestAboveOrder(to price: Double) -> MacdOperation? {
        var diff = Double.greatestFiniteMagnitude
        var closest: MacdOperation?
        
        for otherOrder in self.openOperations {
            guard otherOrder.openPrice >= price else { continue }
            
            let currentDiff = abs(otherOrder.openPrice - price)
            if currentDiff < diff {
                diff = currentDiff
                closest = otherOrder
            }
        }
        
        return closest
    }
    
    /// Returns the closest sell operation whose buy price is lower or equal than the current price.
    private func closestBelowOrder(to price: Double) -> MacdOperation? {
        var diff = Double.greatestFiniteMagnitude
        var closest: MacdOperation?
        
        for otherOrder in self.openOperations {
            guard otherOrder.openPrice <= price else { continue }
            
            let currentDiff = abs(otherOrder.openPrice - price)
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
        let coins: Double = openOperations.reduce(
            0.0,
            { result, newItem in return result + (newItem.quantity) }
        )
        
        var summaryString = ""
        
        summaryString += "==========================================\n"
        summaryString += "Trading history\n"
        summaryString += "==========================================\n"

        
        summaryString += "\n\nExecuted operations.\n"
        summaryString += "\n----------------------\n"
        for closeOrder in self.closedOperations {
            summaryString += closeOrder.description + "\n"
            summaryString += "---\n"
        }
        
        summaryString += "\n\n\n----------------------\n"
        summaryString += "Open sell orders\n"
        summaryString += "\n----------------------\n"
        
        for closeOrder in self.openOperations {
            summaryString += closeOrder.description(currentPrice: currentPrice) + "\n"
            summaryString += "---\n"
        }
        
        let runDuration: TimeInterval = currentDate - startDate
        let profitPercent = Percent(ratioOf: profits, to: initialBalance).percentage
        let profitPerDay = (profits / (runDuration / 3600 / 24))
        let profitPerDayPercent = (profitPercent / (runDuration / 3600 / 24))
        
        summaryString += "\n==========================================\n"
        summaryString += "Summary\n"
        summaryString += "==========================================\n\n"
        
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
    
    private func roundPrice(_ price: Double) -> Double {
        return round(price * 100) / 100.0
    }
    
    private func roundQty(_ qty: Double) -> Double {
        return round(qty * 10e5) / 10e5
    }
}
