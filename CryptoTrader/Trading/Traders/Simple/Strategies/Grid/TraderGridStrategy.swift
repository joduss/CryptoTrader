import Foundation

class TraderGridStrategy: SimpleTraderStrategy {
    
    private let exchange: ExchangeClient
    private let config: TraderGridStrategyConfig
    private let saveStateLocation: String
    
    private let startDate: Date
    private let dateFactory: DateFactory
    
    private var currentAskPrice: Double = 0
    private var currentBidPrice: Double = 0
    private var previousAskPrice: Double = 0
    private var previousBidPrice: Double = 0
    
    private let marketHistory = MarketAggregatedHistory(intervalToKeep: TimeInterval.fromDays(7), aggregationPeriod: TimeInterval.fromMinutes(15))
    
    private let initialBalance: Double
    private var currentBalance: Double
    var balanceValue: Double {
        return currentBalance + gridMarketPositions.filter({$0.open}).reduce(0, {result, order in result + order.qty * currentBidPrice})
    }

    private(set) var profits: Double
        
    private(set) var gridMarketPositions: [GridMarketPosition]
    private(set) var orderHistory: [GridTradeRecord]
    
    var saveEnabled = true
    var openOrders: Int {
        return gridMarketPositions.reduce(0, {result, position in return result + (position.open ? 1 : 0)})
    }
    
    var orderSize: Double {
        if config.orderCount == openOrders { return 0 }
        return currentBalance / Double(config.orderCount -  openOrders)
    }

    private var gridSizePercent: Percent
    
    
    init(
        exchange: ExchangeClient,
        config: TraderGridStrategyConfig,
        initialBalance: Double,
        saveStateLocation: String,
        dateFactory: DateFactory? = nil
    ) {
        self.exchange = exchange
        self.config = config
        self.saveStateLocation = saveStateLocation
        let dateFactory = dateFactory ?? DateFactory.init()
         
        let loadedState = TraderGridStrategy.loadState(location: saveStateLocation)
        
        self.dateFactory = dateFactory
        self.startDate = loadedState?.startDate ?? dateFactory.now
        self.profits = loadedState?.profits ?? 0
        self.initialBalance = loadedState?.initialBalance ?? initialBalance
        self.currentBalance = loadedState?.currentBalance ?? initialBalance
        self.gridMarketPositions = loadedState?.orderGrid ?? []
        self.orderHistory = loadedState?.orderHistory ?? []
        
        gridSizePercent = config.gridSizePercent
    }
    
    // MARK: Saved State
    
    func saveState() {
        guard saveEnabled else { return }
        
        do {
            let state = TraderGridStrategySavedState(startDate: startDate,
                                                     initialBalance: initialBalance,
                                                     currentBalance: currentBalance,
                                                     profits: profits,
                                                     orderGrid: gridMarketPositions,
                                                     orderHistory: orderHistory)
            
            let data = try JSONEncoder().encode(state)
            
            try data.write(to: URL(fileURLWithPath: saveStateLocation))
        } catch {
            sourcePrint("Failed to save the state: \(error)")
        }
    }
    
    class func loadState(location: String) -> TraderGridStrategySavedState? {
        sourcePrint("Loading saved state")
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: location))
            let loadedState = try JSONDecoder().decode(TraderGridStrategySavedState.self, from: data)
            sourcePrint("Loaded saved state")
            return loadedState
        } catch {
            sourcePrint("Failed to restore the state: \(error)")
            return nil
        }
    }
    
    
    // MARK: Strategy interface implementation
    
    func updateTicker(bid: Double, ask: Double) {
        previousAskPrice = currentAskPrice
        previousBidPrice = currentBidPrice
        currentAskPrice = ask
        currentBidPrice = bid
        marketHistory.record(DatedPrice(price: bid, date: dateFactory.now))
        
        adaptGrid()
        updateGrid()
        
        for order in gridMarketPositions {
            if shouldBuy(position: order, askPrice: ask) {
                buy(position: order)
            } else if shouldSell(position: order, bidPrice: bid) {
                sell(position: order)
            }
        }
    }
    
    func buyNow() {
        fatalError("Not implemented")
    }
    
    func sellAll(profit: Percent) {
        fatalError("Not implemented")
    }
    
    func update(report: OrderExecutionReport) {
        fatalError("Not implemented")
    }
    
    func summary(shouldPrint: Bool) -> String {
        var summaryString = ""
        
        summaryString += "==========================================\n"
        summaryString += "Trading history\n"
        summaryString += "==========================================\n"
        
        for order in self.orderHistory {
            summaryString += "\(order.date): Profit \(order.profit £ 2) (\(order.profitPercent.percentage £ 2) %), bought \(order.qty £ 5) @ \(order.buyPrice £ 2) for \(order.buyValue £ 2) then sold @ \(order.sellPrice) for \(order.sellValue)\n"
        }
        
        
        summaryString += "==========================================\n"
        summaryString += "Open Orders\n"
        summaryString += "==========================================\n"
        summaryString += "Current price: \(currentBidPrice)\n"
        
        for order in self.gridMarketPositions.filter({$0.open}) {
            let currentValue = order.qty * currentBidPrice
            let profit = currentBidPrice - order.value
            let profitPercent = Percent(differenceOf: currentValue, from: order.value)
            summaryString += "Order from \(order.openDate!): \(order.qty £ 5)  bought @ \(order.price  £ 2) = \(order.value £ 2) | Current value: \(order.qty * currentBidPrice £ 2) (\(profit £ 2) / \(profitPercent.percentage £ 2)%)\n"
        }
        
        summaryString += "==========================================\n"
        summaryString += "General\n"
        summaryString += "==========================================\n"
        
        let maxPrice = gridMarketPositions.filter({$0.open}).max(by: {$0.price < $1.price})?.price ?? 0
        
        summaryString += "Duration: \((dateFactory.now - startDate)/3600/24) days.\n"
        summaryString += "Open orders: \(openOrders) / \(config.orderCount)\n"
        summaryString += "Current price: \(currentBidPrice.format(decimals: 3))\n"
        summaryString += "Initial balance: \(initialBalance.format(decimals: 3))\n"
        summaryString += "Net worth: \(balanceValue £ 3)\n"
        summaryString += "Net worth at max price: \(gridMarketPositions.reduce(0.0, {$0 + $1.qty}) * maxPrice + currentBalance)\n"
        summaryString += "Profits: \(profits £ 2)\n"

        return summaryString
    }
    
    // MARK: Grid update
    
    private func adaptGrid() {
        let previousGridSize = gridSizePercent
        
        if marketHistory.prices(last: TimeInterval.fromDays(1), before: dateFactory.now).trend() > config.scenarioPriceDropThresholdPercent {
            gridSizePercent = config.gridSizePercent
        }
        else {
            gridSizePercent = config.gridSizeScenarioPriceDropPercent
        }
        
        if gridSizePercent == previousGridSize { return }
        clearNonOpenPositions()
    }
    
    private func clearNonOpenPositions() {
        var positionsToRemove: [GridMarketPosition] = []
        for position in gridMarketPositions {
            if position.open { continue }
            positionsToRemove.append(position)
        }
        
        for position in positionsToRemove {
            gridMarketPositions.remove(position)
        }
    }
    
    private func updateGrid() {
        let currentPrice = currentAskPrice
        guard let maxGridPosition = gridMarketPositions.max(by: {$0.targetPriceBottom < $1.targetPriceBottom})?.targetPriceBottom else {
            gridMarketPositions.append(GridMarketPosition(targetPriceBottom: currentPrice))
            return
        }
        guard let minGridPosition = gridMarketPositions.min(by: {$0.targetPriceBottom < $1.targetPriceBottom})?.targetPriceBottom else {
            return
        }
        
        if currentPrice > maxGridPosition {
            gridMarketPositions.append(GridMarketPosition(targetPriceBottom: maxGridPosition +% self.gridSizePercent))
        }
        if currentPrice < minGridPosition {
            gridMarketPositions.append(GridMarketPosition(targetPriceBottom: minGridPosition -% self.gridSizePercent))
        }
        
        gridMarketPositions.sort(by: {$0.targetPriceBottom < $1.targetPriceBottom})
        
        // Cleanup
        var positionsToRemove: [GridMarketPosition] = []
        for position in gridMarketPositions {
            if position.open { continue }
            if position.targetPriceBottom > currentAskPrice +% Percent(3 * self.gridSizePercent.percentage)  {
                positionsToRemove.append(position)
                continue
            }
            if position.targetPriceBottom < currentBidPrice -% Percent(3 * self.gridSizePercent.percentage) {
                positionsToRemove.append(position)
            }
        }
        
        for position in positionsToRemove {
            gridMarketPositions.remove(position)
        }
    }
    
    // MARK: Market decision making
    
    private func shouldBuy(position: GridMarketPosition, askPrice: Double) -> Bool {
        guard position.open == false else { return false }
        guard orderSize > 0 else { return false }
        if previousBidPrice == 0 { return false }
        
        // Large loss
        let slice = marketHistory.prices(last: TimeInterval.fromDays(1), before: dateFactory.now)

        if Percent(differenceOf: askPrice, from: slice.maxPrice()) < config.scenarioPriceDropThresholdPercent && askPrice < slice.average() {
            clearNonOpenPositions()
            return false
        }
        
        if askPrice < position.targetPriceBottom -% config.buyStopLossPercent {
            position.openable = true
        }
        
        // IDEA: Allow buy only if price was lower
        if position.stopLoss == 0 {
            if position.openable && askPrice > position.targetPriceBottom && previousAskPrice < position.targetPriceBottom {
                return true
            }
            if askPrice > position.targetPriceBottom -% config.buyStopLossPercent { return false }
            position.stopLoss = askPrice +% config.buyStopLossPercent
            return false
        }
        
        if (askPrice +% config.buyStopLossPercent < position.stopLoss) {
            position.stopLoss = askPrice +% config.buyStopLossPercent
            return false
        }
        
        return askPrice > position.stopLoss
    }
    
    private func shouldSell(position: GridMarketPosition, bidPrice: Double)  -> Bool {
        guard position.open == true else { return false }
        
        if Percent(differenceOf: bidPrice, from: position.price) < config.sellStopLossPercent {
            // stop loss
            return  true
        }
        
        if position.stopLoss == 0 {
            if Percent(differenceOf: bidPrice, from: position.price) > config.profitMinPercent {
                position.stopLoss = bidPrice -% config.profitStopLossPercent
            }
            return false
        }
        
        if bidPrice -% config.profitStopLossPercent > position.stopLoss {
            position.stopLoss = bidPrice -% config.profitStopLossPercent
            return false
        }
        
        return bidPrice < position.stopLoss
    }
    
    // MARK: Market action
    
    private func buy(position: GridMarketPosition) {
        let idGenerator = TraderBTSIdGenerator(
            id: position.targetPriceBottom.description,
            date: dateFactory.now,
            action: "BUY",
            price: currentAskPrice
        )

        let order = TradeOrderRequest.marketBuy(
            symbol: exchange.symbol,
            value: orderSize,
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

                        position.price = order.price
                        position.qty = order.originalQty
                        position.value = order.cummulativeQuoteQty
                        position.stopLoss = 0
                        position.openDate = self.dateFactory.now
                        self.currentBalance -= order.cummulativeQuoteQty
                        
                        sourcePrint("Successfully bought \(order.originalQty £ 5) @ \(order.price £ 3) for \(order.cummulativeQuoteQty £ 5) (\(order.status))")
                }
                semaphore.signal()
            }
        )

        semaphore.wait()
        saveState()
    }
    
    private func sell(position: GridMarketPosition) {
        let orderId = TraderBTSIdGenerator(
            id: position.targetPriceBottom.description,
            date: dateFactory.now,
            action: "SELL",
            price: currentBidPrice
        )
        
        let order = TradeOrderRequest.marketSell(
            symbol: exchange.symbol,
            qty: position.qty,
            id: orderId.generate()
        )
        
        let semaphore = DispatchSemaphore(value: 0)
        
        exchange.trading.send(
            order: order,
            completion: { result in
                switch result {
                    case let .failure(error):
                        sourcePrint(
                            "Failed to create the order \(order) on the exchange for the position \(order). (\(error)"
                        )
                        break
                    case let .success(order):
                        if order.status != .filled {
                            sourcePrint("ERROR: market order NOT FILLED!!!")
                        }
                                                
                        sourcePrint("Sold the operation \(order.description)")
                        
                        self.currentBalance += order.cummulativeQuoteQty
                        
                        let tradeRecord = position.sell(at: order.price, value: order.cummulativeQuoteQty, date: self.dateFactory.now)
                         self.profits += tradeRecord.profit
                        sourcePrint("Successfully sold \(order.originalQty.format(decimals: 3)) @ \(order.price.format(decimals: 3)) = \(order.cummulativeQuoteQty)")
                        self.orderHistory.append(tradeRecord)
                }
                semaphore.signal()
            }
        )
        saveState()
        semaphore.wait()
    }
    
    
}
