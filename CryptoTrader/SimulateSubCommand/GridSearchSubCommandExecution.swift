import Foundation

class GridSearchSubCommandExecution {
    
    let symbol: CryptoSymbol
    var tickers: ContiguousArray<MarketTicker> = ContiguousArray<MarketTicker>()
    
    private let testSema = DispatchSemaphore(value: 1)
    
    private let initialBalance: Double = 100.0

    
    internal init(symbol: CryptoSymbol,
                  dataLocation: String,
                  dataStartIdx: Int? = nil,
                  dataEndIdx: Int? = nil,
                  keepEvery: Int = 1) throws {
        self.symbol = symbol
        
        let startIdx = dataStartIdx ?? 0
        let endIdx = dataEndIdx ?? Int.max
        
        if (dataLocation.contains(".tickers")) {
            self.tickers = MarketTickerDeserializer.loadTickers(from: dataLocation,
                                                                startIdx: startIdx,
                                                                endIdx: endIdx)
        }
        else {
            self.tickers = MarketMinimalAggregatedTradeDeserializer.loadTradesAsTickers(from: dataLocation,
                                                                                        startIdx: startIdx,
                                                                                        endIdx: endIdx,
                                                                                        keepEvery: keepEvery,
                                                                                        symbol: symbol)
        }
            
        
    }
    
    /// Returns (profits, summary)
    func execute(strategy: TradingStrategy) {
        switch strategy {
            case .bts:
                gridSearchBTS()
            case .macd:
                return gridSearchMacd()
            case .gridtrader:
                fatalError("NOT IMPLEMENTED")
        }
    }
    
    /// Returns (profits, summary)
    private func executeMacd(config: TraderMacdStrategyConfig, dateFactory: DateFactory) -> TradingSimulationResults {
        let simulation = TradingSimulation(symbol: symbol,
                                           simulatedExchange: createSimulatedExchange(dateFactory: dateFactory),
                                           dateFactory: dateFactory,
                                           initialBalance: initialBalance)
        simulation.shouldPrint = false
        
        return simulation.simulate(config: config)
    }
    
    /// Returns (profits, summary)
    func executeBTS(config: TraderBTSStrategyConfig, dateFactory: DateFactory) -> TradingSimulationResults {
        
        let simulation = TradingSimulation(symbol: symbol,
                                           simulatedExchange: createSimulatedExchange(dateFactory: dateFactory),
                                           dateFactory: dateFactory,
                                           initialBalance: initialBalance)
        simulation.shouldPrint = false
        
        return simulation.simulate(config: config)
    }
    
    private func createSimulatedExchange(dateFactory: DateFactory) -> SimulatedTickerBasedExchange {
        return SimulatedTickerBasedExchange(symbol: symbol, tickers: tickers, dateFactory: dateFactory)
    }
    
    
    
    /// Grid search for BTS Strategy
    private func gridSearchBTS() {
        
        print("Simulation with initial balance: \(initialBalance)")
        
        sourcePriceHidden = true
        
        var results: [TradingSimulationResults] = []
        
        let queue = OperationQueue()
        let group = DispatchGroup()
        
        queue.maxConcurrentOperationCount = 16
        
        var parametersAndProfits = [String]()
        var operationCount = 0
        
        parametersAndProfits.append("maxOrder,"
                                        + "minDistancePercentNegative,"
                                        + " minDistancePercentPositive,"
                                        + "buyStopLossPercent,"
                                        + "sellStopLossProfitPercent,"
                                        + "lockTrendThreshold,"
                                        + "unlockTrendThreshold,"
                                        + "lock2LossesInLast,"
                                        + "unlockCheckTrendInterval,"
                                        + "lockCheckTrendInterval,"
                                        + "lockStrictInterval,"
                                        + "dipDropThresholdTime,"
                                        + "dipDropThresholdPercent,"
                                        + "sellMinProfitPercent,"
                                        + "minSellStopLossProfitPercent,"
                                        + "sellStopLossPercent,"
                                        + "openOrders,"
                                        + "accumulatedProfits,"
                                        + "currentValue")
        
        
        // BTC
//        for maxOrder in [15] { // 18
//            for buyStopLossPercent in [0.4, 0.6] { // 0.8
//                for sellStopLossProfitPercent in [0.25, 0.5] { // 0.5
//                    for minDistancePercentNegative in [-0.2] { // -0.2
//                        for minDistancePercentPositive in [0.3] { // 0.4
//                            for lockTrendThreshold in [0.0] { // 0
//                                for unlockTrendThreshold in [0.1] { // 0
//                                    for lock2LossesInLast in [12.0] { // 12 hours
//                                        for unlockCheckTrendInterval in [6.0] { // 6
//                                            for lockCheckTrendInterval in [1.0] { // 1 (very clear)
//                                                for lockStrictInterval in [180.0] {// minutes // 180 OK
//                                                    for dipDropThresholdPercent in [3.5] { // 1.5
//                                                        for dipDropThresholdTime in [45.0] { // 45
//                                                            for sellMinProfitPercent in [1.3] { // 0.9
//                                                                for minSellStopLossProfitPercent in [sellStopLossProfitPercent] {
                for maxOrder in [12] { // 18
                    for buyStopLossPercent in [0.4, 0.8, 1.2] {
                        for sellStopLossProfitPercent in [0.25, 0.5, 0.75, 1] {
                            for minDistancePercentNegative in [-0.3, -0.6, -1, -1.5] {
                                for minDistancePercentPositive in [0.3, 0.5, 1] {
                                    for lockTrendThreshold in [0.0] { // 0
                                        for unlockTrendThreshold in [0.1] { // 0
                                            for lock2LossesInLast in [24, 72, 150] { // 12 hours
                                                for unlockCheckTrendInterval in [6.0, 12] { // 6
                                                    for lockCheckTrendInterval in [1.0] { // 1 (very clear)
                                                        for lockStrictInterval in [180.0] {// minutes // 180 OK
                                                            for dipDropThresholdPercent in [3.5] { // 1.5
                                                                for dipDropThresholdTime in [45.0] { // 45
                                                                    for sellMinProfitPercent in [1.3, 0.8] {
                                                                        for sellStopLossPercent in [-7.0, -9.0, -10, -12] {
                                                                            for minSellStopLossProfitPercent in [sellStopLossProfitPercent] {
                                                                                
                                                                                // ETH
                                                                                //        for maxOrder in [15, 18] {
                                                                                //            for buyStopLossPercent in [0.5, 0.8] { // 0.8, clear
                                                                                //                for sellStopLossProfitPercent in [0.45, 0.8, 0.9, 1.2] { // 0.25
                                                                                //                    for minDistancePercentNegative in [-0.2, -0.4, -0.6, -0.8] { // -0.2
                                                                                //                        for minDistancePercentPositive in [0.2, 0.4, 0.6, 1] { //0.6
                                                                                //                            for lockTrendThreshold in [0.0] { // 0
                                                                                //                                for unlockTrendThreshold in [0.0] { // 0
                                                                                //                                    for lock2LossesInLast in [12.0] { // 12 hours
                                                                                //                                        for unlockCheckTrendInterval in [3, 6.0, 10] { // 3
                                                                                //                                            for lockCheckTrendInterval in [1.0, 6] { // hours // 8
                                                                                //                                                for lockStrictInterval in [60, 180.0] {// minutes // 180
                                                                                //                                                    for dipDropThresholdPercent in [1.5] { // 1.5
                                                                                //                                                        for dipDropThresholdTime in [45.0] { // 30
                                                                                //                                                            for sellMinProfitPercent in [0.4, 0.6, 0.9] {
                                                                                //                                                                for minSellStopLossProfitPercent in [sellStopLossProfitPercent] {
                                                                                
                                                                                // ICX
                                                                                //        for maxOrder in [5] {
                                                                                //            for buyStopLossPercent in [0.5, 0.8, 1.3, 1.8, 2.5] { // 0.8, clear
                                                                                //                for sellStopLossProfitPercent in [0.5, 0.8, 1.3, 1.8, 2.5] { // 0.25
                                                                                //                    for minDistancePercentNegative in [-0.4, -0.6, -0.8, -1, -1.2, -1.7] { // -0.2
                                                                                //                        for minDistancePercentPositive in [0.4, 0.8, 1.2, 1.5] { //0.6
                                                                                //                            for lockTrendThreshold in [0.0] { // 0
                                                                                //                                for unlockTrendThreshold in [0.0] { // 0
                                                                                //                                    for lock2LossesInLast in [12.0] { // 12 hours
                                                                                //                                        for unlockCheckTrendInterval in [3, 6.0, 10] { // 3
                                                                                //                                            for lockCheckTrendInterval in [1.0, 6] { // hours // 8
                                                                                //                                                for lockStrictInterval in [60, 180.0] {// minutes // 180
                                                                                //                                                    for dipDropThresholdPercent in [1.5] { // 1.5
                                                                                //                                                        for dipDropThresholdTime in [45.0] { // 30
                                                                                //                                                            for sellMinProfitPercent in [0.4, 0.6, 0.9, 1.3, 1.7, 2] {
                                                                                //                                                                for minSellStopLossProfitPercent in [sellStopLossProfitPercent] {
                                                                                
                                                                                
                                                                                operationCount += 1
                                                                                queue.progress.totalUnitCount = Int64(operationCount)
                                                                                
                                                                                group.enter()
                                                                                
                                                                                var config = TraderBTSStrategyConfigBTC() // Not important, we set each value.
                                                                                config.maxOrdersCount = maxOrder
                                                                                config.buyStopLossPercent = Percent(buyStopLossPercent)
                                                                                config.minDistancePercentPositive = Percent(minDistancePercentPositive)
                                                                                config.minDistancePercentNegative = Percent(minDistancePercentNegative)
                                                                                
                                                                                config.unlockTrendThreshold = Percent(unlockTrendThreshold)
                                                                                config.lockTrendThreshold = Percent(lockTrendThreshold)
                                                                                config.lock2LossesInLast = TimeInterval.fromHours(lock2LossesInLast)
                                                                                config.unlockCheckTrendInterval = TimeInterval.fromHours(unlockCheckTrendInterval)
                                                                                config.lockCheckTrendInterval = TimeInterval.fromHours(lockCheckTrendInterval)
                                                                                config.lockStrictInterval = TimeInterval.fromMinutes(lockStrictInterval)
                                                                                config.dipDropThresholdTime = TimeInterval.fromMinutes(dipDropThresholdTime)
                                                                                config.dipDropThresholdPercent = Percent(dipDropThresholdPercent)
                                                                                
                                                                                config.sellStopLossProfitPercent = Percent(sellStopLossProfitPercent)
                                                                                config.sellMinProfitPercent = Percent(sellMinProfitPercent)
                                                                                config.minSellStopLossProfitPercent = Percent(minSellStopLossProfitPercent)
                                                                                
                                                                                config.stopLossPercent = Percent(sellStopLossPercent)
                                                                                
                                                                                var operationId = operationCount
                                                                                
                                                                                queue.addOperation {
                                                                                    print("Starting operation \(operationId)")
                                                                                    let dateFactory = DateFactory()
                                                                                    dateFactory.now = self.tickers.first!.date
                                                                                    
                                                                                    let simulationResults = self.executeBTS(config: config, dateFactory: dateFactory)
                                                                                    
                                                                                    self.testSema.wait()
                                                                                    results.append(simulationResults)
                                                                                    print("Progress: \(queue.progress.completedUnitCount) / \(queue.progress.totalUnitCount) (\(queue.progress.fractionCompleted * 100)%)")
                                                                                    
                                                                                    let parameters: String =
                                                                                        "\(maxOrder),"
                                                                                        + "\(minDistancePercentNegative),"
                                                                                        + "\(minDistancePercentPositive),"
                                                                                        + "\(buyStopLossPercent),"
                                                                                        + "\(sellStopLossProfitPercent),"
                                                                                        + "\(lockTrendThreshold),"
                                                                                        + "\(unlockTrendThreshold),"
                                                                                        + "\(lock2LossesInLast),"
                                                                                        + "\(unlockCheckTrendInterval),"
                                                                                        + "\(lockCheckTrendInterval),"
                                                                                        + "\(lockStrictInterval),"
                                                                                        + "\(dipDropThresholdTime),"
                                                                                        + "\(dipDropThresholdPercent),"
                                                                                        + "\(sellMinProfitPercent),"
                                                                                        + "\(minSellStopLossProfitPercent),"
                                                                                        + "\(sellStopLossPercent),"
                                                                                        + "\(simulationResults.openOrderCount),"
                                                                                        + "\(simulationResults.accumulatedProfits),"
                                                                                        + "\(simulationResults.currentValue),"
                                                                                    
                                                                                    parametersAndProfits.append(parameters)
                                                                                    
                                                                                    self.testSema.signal()
                                                                                    group.leave()
                                                                                }
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                                
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
        
        
    print("Total operations: \(queue.operationCount)")
        
        queue.waitUntilAllOperationsAreFinished()
        group.wait()
        print(parametersAndProfits)
        
        let parametersPath = ("~/Desktop/parameters_bts.csv" as NSString).expandingTildeInPath
        let outputPath = ("~/Desktop/output_bts.txt" as NSString).expandingTildeInPath
        
        try! parametersAndProfits.joined(separator: "\n")
            .data(using: .utf8)!
            .write(to: URL(fileURLWithPath: parametersPath))
        
        try! results.map(
            { r in
                "########################################\n"
                    + "Result\n"
                    + "########################################\n\n"
                    + "Profits => \(r.accumulatedProfits) / Balance => \(r.currentValue) / OpenOrders: \(r.openOrderCount)\n\n"
                    + r.simulationLog
            })
            .joined(separator: "\n")
            .data(using: .utf8)!.write(to: URL(fileURLWithPath: outputPath))
        
        TraderMain.exit()
    }
    
    
    
    private func gridSearchMacd() {
        
        print("Grid SEARCH MACD")
        
        print("Simulation with initial balance: \(initialBalance)")
        
        sourcePriceHidden = true
        
        var results: [TradingSimulationResults] = []
        
        let queue = OperationQueue()
        let group = DispatchGroup()
        
        var parametersAndProfits = [String]()
        var operationCount = 0
        
        parametersAndProfits.append("maxOrdersCount,"
                                        + "macdPeriod,"
                                        + "minDistancePercentBelow,"
                                        + "minDistancePercentAbove,"
                                        + "minProfitsPercent,"
                                        + "stopLoss,"
                                        + "openOrders,"
                                        + "profits,"
                                        + "currentValue")
        
        // BTC.
        for maxOrdersCount in [5, 8, 12] {
            for macdPeriod in [1, 15, 25, 35, 60] {
                for minDistancePercentBelow in [-0.5, -0.6, -0.75, -1] {
                    for minDistancePercentAbove in [0.3, 0.4, 0.5, 0.6, 0.8, 1] {
                        for minProfitsPercent in [0.2, 0.35, 0.5, 0.65, 0.8] {
                            for stopLoss in [-1000, -1, -0.75, -0.5, -0.4, -0.3] {
                                
                                operationCount += 1
                                queue.progress.totalUnitCount = Int64(operationCount)
                                
                                group.enter()
                                
                                var config = TraderMacdStrategyConfig() // Not important, we set each value.
                                config.maxOrdersCount = maxOrdersCount
                                config.macdPeriod = macdPeriod // in minutes
                                config.minDistancePercentBelow = Percent(minDistancePercentBelow)
                                config.minDistancePercentAbove = Percent(minDistancePercentAbove)
                                config.stopLossPercent = Percent(stopLoss)
                                config.minProfitsPercent = Percent(minProfitsPercent)
                                
                                
                                queue.addOperation {
                                    let dateFactory = DateFactory()
                                    dateFactory.now = self.tickers.first!.date
                                    
                                    let simulationResults = self.executeMacd(config: config, dateFactory: dateFactory)
                                    
                                    self.testSema.wait()
                                    results.append(simulationResults)
                                    print("Progress: \(queue.progress.completedUnitCount) / \(queue.progress.totalUnitCount) (\(queue.progress.fractionCompleted * 100)%)")
                                    
                                    let parameters: String =
                                        "\(maxOrdersCount),"
                                        + "\(macdPeriod),"
                                        + "\(minDistancePercentBelow),"
                                        + "\(minDistancePercentAbove),"
                                        + "\(minProfitsPercent),"
                                        + "\(stopLoss),"
                                        + "\(simulationResults.openOrderCount),"
                                        + "\(simulationResults.accumulatedProfits),"
                                        + "\(simulationResults.currentValue)"
                                    
                                    parametersAndProfits.append(parameters)
                                    
                                    self.testSema.signal()
                                    group.leave()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        
        queue.maxConcurrentOperationCount = 1
        
        print("Total operations: \(queue.operationCount)")
        
        queue.waitUntilAllOperationsAreFinished()
        group.wait()
        print(parametersAndProfits)
        
        let parametersPath = ("~/Desktop/parameters_macd.csv" as NSString).expandingTildeInPath
        let outputPath = ("~/Desktop/output_macd.txt" as NSString).expandingTildeInPath
        
        try! parametersAndProfits.joined(separator: "\n")
            .data(using: .utf8)!
            .write(to: URL(fileURLWithPath: parametersPath))
        
        try! results.map(
            { r in
                "########################################\n"
                    + "Result\n"
                    + "########################################\n\n"
                    + "Profits => \(r.accumulatedProfits) / Balance => \(r.currentValue) / OpenOrders: \(r.openOrderCount)\n\n"
                    + r.simulationLog
            })
            .joined(separator: "\n")
            .data(using: .utf8)!.write(to: URL(fileURLWithPath: outputPath))
        
        TraderMain.exit()
    }
}
