import Foundation
import tulipindicators


fileprivate enum MACDState {
    case unknown
    case above
    case below
}

class TraderMACDStrategy: SimpleTraderStrategy {
    
    
    // MARK: Configuration
    // -------------------------------
    var saveEnabled = true
    
    private let saveStateLocation: String
    
    private let exchange: ExchangeClient
    
    private let config: TraderMacdStrategyConfig
    
    private let symbol: CryptoSymbol
    
    // MARK: State
    // -------------------------------
    private let dateFactory: DateFactory
    private(set) var startDate: Date
    var currentDate: Date { return dateFactory.now }
    
    private var initialBalance: Decimal
    
    private var currentBalance: Decimal = 0
    
//    private var currentBalance: Double {
//        didSet { sourcePrint("Current Balance: \(oldValue) -> \(currentBalance)") }
//    }
    
    private(set) var profits: Decimal = 0
    
    private var orderValue: Decimal = 0

    private var currentBidPrice: Decimal = 0
    private var currentAskPrice: Decimal = 0
    
    private var openOperations: [MacdOperation] = []
    private var closedOperations: [MacdOperation] = []
    
    
    private var macdState = MACDState.unknown

    private var queue = Queue<Decimal>()
    
    private let macdIndicator: MacdIndicator
    
    private var csvLine: TraderMACDStrategyCSVLine
    private var csvInitialized = false
    
    

    
    // MARK: Computed properties
    // -------------------------------
    
    private var lastBuyPrice: Decimal? {
        return openOperations.last?.openPrice
    }
    
    private var lastBuyOrder: MacdOperation? {
        return openOperations.last
    }
    
    private var lastOperationDate: Date {
        return
            self.openOperations.last?.openDate ??
            self.closedOperations.last?.closeDate ??
            Date(timeIntervalSince1970: 0)
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
        initialBalance: Decimal,
        currentBalance: Decimal,
        saveStateLocation: String,
        dateFactory: DateFactory? = nil
    ) {
        self.config = config
        self.exchange = exchange
        self.symbol = exchange.symbol
        self.initialBalance = initialBalance
        self.orderValue = initialBalance / Decimal(config.maxOrdersCount)
        self.saveStateLocation = saveStateLocation
        self.currentBalance = currentBalance
        self.dateFactory = dateFactory ?? DateFactory.init()
        self.startDate = self.dateFactory.now
        
        self.macdIndicator = MacdIndicator(shortPeriod: config.macdShort, longPeriod: config.macdLong, signalPeriod: config.macdSignal)
                
        queue.reserveCapacity(config.macdLong)
        queue.limitSize = config.macdLong * 2

        FileManager.default.createFile(atPath: "/Users/jonathanduss/Desktop/macd-buy-analysis.csv", contents: nil, attributes: nil)
        csvLine = TraderMACDStrategyCSVLine(file: FileHandle(forWritingAtPath: "/Users/jonathanduss/Desktop/macd-buy-analysis.csv")!,
                                            date: Date(),
                                            bidPrice: 0,
                                            buy: nil,
                                            sell: nil)
        csvLine.writeHeader()
        
        self.restore()
        
        // Balance update. (Might be more, might be less)
        guard initialBalance != self.initialBalance else { return }
        let balanceChange = initialBalance - self.initialBalance
        
        guard currentBalance + balanceChange >= 0 else {
            fatalError("The balance cannot be decreased: the current balance would be negative.")
        }
        
        self.initialBalance = initialBalance
        self.currentBalance = self.currentBalance + balanceChange
        self.orderValue = self.currentBalance / Decimal(config.maxOrdersCount - openOperations.count)
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
    
    private var nextSellDecisionAfter = Date(timeIntervalSince1970: 0)

    func updateTicker(bid: Decimal, ask: Decimal) {
        
        if (csvInitialized) {
            csvLine.write()
        }
        csvInitialized = true
        
        csvLine.date = currentDate
        csvLine.bidPrice = bid
        
        self.currentBidPrice = bid
        enqueueBid(bid)
        
        stopLoss(bidPrice: bid)
        
        if macdState == .above,
           let closedOpPriceBelow = closestBelowOrder(to: bid)?.openPrice,
           Percent(differenceOf: closedOpPriceBelow, from: bid) > config.minProfitsPercent {
            buy()
            return
        }
        
        guard nextSellDecisionAfter < currentDate else { return }
        nextSellDecisionAfter = currentDate + TimeInterval.fromMinutes(15)
        
        let macd = macdIndicator.compute(on: queue.toArray())
        csvLine.macd = macd.macdLine.last!
        csvLine.signal = macd.signalLine.last!
        
        if macd.macdLine.last! > macd.signalLine.last!, macdState == .below { //}, mcadSignal < -20 else {
            updateAsk(price: ask, macd: macd)
            macdState = .above
        } else if macd.macdLine.last! < macd.signalLine.last!, macdState == .above {
            updateBid(price: bid, macd: macd)
            macdState = .below
        } else if macdState == .unknown {
            macdState = macd.macdLine.last! < macd.signalLine.last! ? .below : .above
        }
    }
    
    
    // MARK: Decision about BUY
    // ================================================================
            
    /// Called on second
    func updateAsk(price: Decimal, macd: Macd) {
        self.currentAskPrice = price
        
        /// There are always sufficient found here!
        /// There are 2h of statistic availables
        /// We usually want to create order "STOP-LOSS BUY", which we update if the price continues to go down,
        /// at least if there is a clear downward trend.
        guard openOperations.count < config.maxOrdersCount else { return }
        
        guard queue.toArray().count == queue.limitSize else { return }
        
//        var stochRsiValue = stochrsi(queue.toArray(), period: 128)
        
//        guard stochRsiValue.1.last! < 0.6 else { return }
        
        // Min distance below
        guard !isTooClose(price: price) else {
            return
        }
        
        let mcadValue = macd.macdLine.last!
        let mcadSignal = macd.signalLine.last!
                
        if buy() {
            sourcePrint("Bought @ \(price) because macd / signal => \(mcadValue) / \(mcadSignal)")
        }
    }
    

    
    /// Send a buy order to the exchange platform for the given operation.
    @discardableResult
    private func buy() -> Bool {
        
        if orderValue > currentBalance {
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

                        sourcePrint("Successfully bought \(order.originalQty) @ \(order.price) (\(order.status))")
                        
                        self.csvLine.buy = order.price
                }
                semaphore.signal()
            }
        )
        
        semaphore.wait()
        saveState()
        
        return true
    }
    
    private func isTooClose(price: Decimal) -> Bool {
        if let aboveOperation = openOperations.filter({$0.openPrice > price}).min(by: {$0.openPrice < $1.openPrice}) {
            return Percent(differenceOf: price, from: aboveOperation.openPrice) > config.minDistancePercentBelow ?? 0
        }
        
        if let belowOperation = openOperations.filter({$0.openPrice < price}).max(by: {$0.openPrice < $1.openPrice}) {
            return Percent(differenceOf: price, from: belowOperation.openPrice) < config.minDistancePercentAbove ?? 0
        }
        
        return false
    }
    
    
    
    // MARK: Decisiong about selling
    // =================================================================
    
    func stopLoss(bidPrice: Decimal) {
        // Need a STOP LOSS
        if let op = openOperations.first, Percent(differenceOf: bidPrice, from: op.openPrice) < config.stopLossPercent {
            sell(operation: op)
            saveState()
            return
        }
    }
    
    /// Called first.
    func updateBid(price: Decimal, macd: Macd) {
        
        guard let mcadValue = macd.macdLine.last,
              let mcadSignal = macd.signalLine.last else {
            return
        }
        
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
                        
                        self.orderValue += operation.profits! / Decimal(self.config.maxOrdersCount)
                        self.currentBalance += order.cummulativeQuoteQty
                        self.profits += operation.profits!
                        
                        self.csvLine.sell = order.price

                }
                semaphore.signal()
            }
        )
        semaphore.wait()
    }
    
    
    // MARK: - Helpers
    // =================================================================
    
    /// Returns the closest sell operation whose buy price is higher or equal than the current price.
    private func closestAboveOrder(to price: Decimal) -> MacdOperation? {
        var diff = Decimal.greatestFiniteMagnitude
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
    private func closestBelowOrder(to price: Decimal) -> MacdOperation? {
        var diff = Decimal.greatestFiniteMagnitude
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
    
    // MARK: - Queue
    // =================================================================

    private var lastPeriodStart: Date = Date(timeIntervalSince1970: 0)
    
    func enqueueBid(_ bidPrice: Decimal) {
        
        if currentDate - lastPeriodStart > TimeInterval(config.macdPeriod * 60) {
            lastPeriodStart = currentDate
            queue.enqueue(bidPrice)
        }
        else {
            queue.replaceLast(bidPrice)
        }
    }
    
    
    // MARK: - Information Display
    // =================================================================
    
    @discardableResult
    func summary(shouldPrint: Bool = true) -> String {
        let currentPrice = currentBidPrice
        let coins: Decimal = openOperations.reduce(
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
        let profitPerDay: Decimal = (profits / Decimal(runDuration / 3600 / 24))
        let profitPerDayPercent: Decimal = (profitPercent / Decimal(runDuration / 3600 / 24))
        
        summaryString += "\n==========================================\n"
        summaryString += "Summary\n"
        summaryString += "==========================================\n\n"
        
        summaryString += "Strategy type: MACD\n"
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
    
//    private func aggregateStatistics() -> [Double] {
//        self.marketStatistic
//            .aggregateClose(by: TimeInterval.fromMinutes(config.macdPeriod), from: currentDate)
//            .prices
//            .map({$0.price})
//    }
}
