import Foundation
import ArgumentParser
import JoLibrary

extension TraderMain {
    
    struct Simulate: ParsableCommand {
        
        // MARK: Command line options, arguments, etc
        // ------------------------------
        
        @Flag(exclusivity: .chooseFirst, help: "The market pair.")
        var symbol: CryptoSymbol = .btc_usd
        
        @Option(name: .customShort("b"), help: "Initial balance available for trading. (Ignored in grid-search)")
        var initialBalance: Double
        
        @Option(name: .customShort("c"), help: "Number of operation that can be open. (Ignored in grid-search)")
        var maxOperationCount: Int
        
        @Argument
        var saveStateLocation: String
        
        @Argument
        var tickersLocation: String
        
        @Flag(help: "Run a grid search to find best parameters")
        var gridSearch: Bool = false
        
        // MARK: Command line main.
        // ------------------------------
        func run() throws {
            let _ = try SimulateSubCommand(symbol: symbol,
                                           initialBalance: initialBalance,
                                           maxOperationCount: maxOperationCount,
                                           saveStateLocation: saveStateLocation,
                                           tickersLocation: tickersLocation,
                                           gridSearch: gridSearch)
        }
    }
}

class SimulateSubCommand {
    
    let symbol: CryptoSymbol
    var initialBalance: Double
    let maxOperationCount: Int
    let saveStateLocation: String
    
    let tickers: ContiguousArray<MarketTicker>
    
    
    internal init(symbol: CryptoSymbol, initialBalance: Double, maxOperationCount: Int, saveStateLocation: String, tickersLocation: String, gridSearch: Bool) throws {
        
        let reader = TextFileReader.openFile(at: tickersLocation)
        var idx = 0
        let keepEveryNTicker = 15
        
        var tickersRead = ContiguousArray<MarketTicker>()
        tickersRead.reserveCapacity(50000000)
        
        while true {
            
            guard let line = reader.readLine() else {
                break
            }
            
            idx += 1
            
            if (idx % 1000000 == 0) { print(idx) }
//            if idx < 26000000 { continue }
//            if idx > 1000000 { break }
            if (idx % keepEveryNTicker != 0) { continue }

            let ticker = SimulateSubCommand.parse(line: line)
            
//            let startDate: Date = Date(timeIntervalSinceReferenceDate: 635846400) // begining of last week
////            let startDate: Date = Date(timeIntervalSinceReferenceDate: 636156000) // samedi soir
//            let endDate: Date = Date()
//
//
//            if ticker.date < startDate {
//                continue
//            }
//
//            if ticker.date > endDate {
//                break
//            }
            
            tickersRead.append(ticker)
        }
        
        let time = tickersRead.last!.date
        let addTime = TimeInterval.fromMilliseconds(300)
        let tickersReadReversed = Array(tickersRead.reversed())
        
        var i = 0
        let tickersCount = tickersRead.count
        while(i < tickersCount) {
            var ticker = tickersReadReversed[i]
            ticker.date = time + addTime * Double(i)
            tickersRead.append(ticker)
            i += 1
        }
        
        self.tickers = tickersRead
        
        self.symbol = symbol
        self.initialBalance = initialBalance
        self.maxOperationCount = maxOperationCount
        self.saveStateLocation = saveStateLocation
        
        if gridSearch {
            self.gridSearch()
            return
        }
        
        simulate()
        return
    }
    
    private func simulate() {
        sourcePriceHidden = false
        
        var config: TraderBTSStrategyConfig!
        
        switch symbol {
            case .btc_usd:
                config = TraderBTSStrategyConfigBTC()
                break
            case .eth_usd:
                config = TraderBTSStrategyConfigETH()
            case .icx_usd:
                config = TraderBTSStrategyConfigICX()
        }
        
        config.maxOrdersCount = maxOperationCount
        
        
        let dateFactory = DateFactory()
        printDateFactory = dateFactory
        dateFactory.now = self.tickers.first!.date
        simulate(config: config, dateFactory: dateFactory, printPrice: true)
        
        var rerun = false
        
        if rerun {
            simulate()
        }
    }
    
    let testSema = DispatchSemaphore(value: 1)
    
    private func gridSearch() {
        
        
        initialBalance = 152
        print("Simulation with initial balance: \(initialBalance)")

        sourcePriceHidden = true
        
        var results: [(Double, String)] = []
        
        let queue = OperationQueue()
        let group = DispatchGroup()
        
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
                                        + "simulationResults")
        
        
        // BTC
        for maxOrder in [18] { // 18
            for buyStopLossPercent in [0.8] { // 0.8
                for sellStopLossProfitPercent in [0.5] { // 0.5
                    for minDistancePercentNegative in [-0.2] { // -0.2
                        for minDistancePercentPositive in [0.4] { // 0.4
                            for lockTrendThreshold in [0.0] { // 0
                                for unlockTrendThreshold in [0.0] { // 0
                                    for lock2LossesInLast in [16.0] { // 12 hours
                                        for unlockCheckTrendInterval in [6.0] { // 6 (very clear)
                                            for lockCheckTrendInterval in [1.0] { // 1 (very clear)
                                                for lockStrictInterval in [180.0] {// minutes // 180
                                                    for dipDropThresholdPercent in [1.5] { // 1.5
                                                        for dipDropThresholdTime in [45.0] { // 45
                                                            for sellMinProfitPercent in [0.9] { // 0.9
                                                                for minSellStopLossProfitPercent in [sellStopLossProfitPercent] {
                                                                    
                                                                    // ETH
                                                                    //        for maxOrder in [15] {
                                                                    //            for buyStopLossPercent in [0.8] { // 0.8
                                                                    //                for sellStopLossProfitPercent in [0.6] { // 0.25
                                                                    //                    for minDistancePercentNegative in [-0.2, -0.4, -0.6, -1] { // -0.2
                                                                    //                        for minDistancePercentPositive in [0.2, 0.4, 0.6, 1] { //0.6
                                                                    //                            for nextBuyTargetPercent in [0.5] { // 0.1
                                                                    //                                for nextBuyTargetExpiration in [15.0] { // minutes // 30 (tester encore 15, 30, 60, 90, 120
                                                                    //                                    for lockTrendThreshold in [0.0] { // 0
                                                                    //                                        for unlockTrendThreshold in [0.0] { // 0
                                                                    //                                            for lock2LossesInLast in [12.0] { // 12 hours
                                                                    //                                                for unlockCheckTrendInterval in [3.0] { // 3
                                                                    //                                                    for lockCheckTrendInterval in [8.0] { // hours // 8
                                                                    //                                                        for lockStrictInterval in [180.0] {// minutes // 180
                                                                    //                                                            for dipDropThresholdPercent in [1.5] { // 1.5
                                                                    //                                                                for dipDropThresholdTime in [30.0] { // 30
                                                                    //                                                                    for sellMinProfitPercent in [0.4, 0.9] {
                                                                    //                                                                        for minSellStopLossProfitPercent in [sellStopLossProfitPercent] {
                                                                    
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
                                                                    
                                                                    queue.addOperation {
                                                                        let dateFactory = DateFactory()
                                                                        dateFactory.now = self.tickers.first!.date
                                                                        
                                                                        let simulationResults = self.simulate(config: config, dateFactory: dateFactory)
                                                                        
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
                                                                            + "\(simulationResults.0)"
                                                                        
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
        
        queue.maxConcurrentOperationCount = 4
        
        print("Total operations: \(queue.operationCount)")
        
        queue.waitUntilAllOperationsAreFinished()
        group.wait()
        print(parametersAndProfits)
        
        let parametersPath = ("~/Desktop/parameters.csv" as NSString).expandingTildeInPath
        let outputPath = ("~/Desktop/output.txt" as NSString).expandingTildeInPath

        try! parametersAndProfits.joined(separator: "\n")
            .data(using: .utf8)!
            .write(to: URL(fileURLWithPath: parametersPath))
        
        try! results.map(
            { r in
                "########################################\n"
                    + "Result\n"
                    + "########################################\n\n"
                    + "Profits => \(r.0)\n\n"
                    + r.1
            })
            .joined(separator: "\n")
            .data(using: .utf8)!.write(to: URL(fileURLWithPath: outputPath))
        
        TraderMain.exit()
    }
    
    private func simulate(config: TraderBTSStrategyConfig, dateFactory: DateFactory, printPrice: Bool = false) -> (Double, String) {
        let exchange = SimulatedFullExchange(symbol: symbol, tickers: self.tickers, dateFactory: dateFactory)
        let strategy = SimpleTraderBTSStrategy(exchange: exchange,
                                               config: config,
                                               initialBalance: initialBalance,
                                               currentBalance: initialBalance,
                                               saveStateLocation: saveStateLocation,
                                               dateFactory: dateFactory)
        strategy.saveEnabled = false
        let trader = SimpleTrader(client: exchange, strategy: strategy)
        trader.printCurrentPrice = printPrice
        
        exchange.start()
                
        let description =
            """
            CONFIG: \(config)

            \(strategy.summary(shouldPrint: printPrice))
            """
        
        return (strategy.profits, description)
    }
    
    
    
    
    //"{"symbol":"BTCUSDT","id":8611636536,"date":634547549.01567698,"bidQuantity":186.18478599999997,"askPrice":47650.879999999997,"bidPrice":47650.870000000003,"askQuantity":2.9338730000000006}"
    static func parse(line: String) -> MarketTicker {
        var symbol: CryptoSymbol!
        var id: Int!
        var date: Date!
        var bidQty: Double!
        var askPrice: Double!
        var bidPrice: Double!
        var askQuantity: Double!
        
        var elementIdx = 0
        var accumulated = ""
        var accumulating = false
                
        for char in line {
            if accumulating == false && char == ":" {
                accumulating = true
                accumulated = ""
                accumulated.reserveCapacity(20)
                continue
            }
            else if accumulating == false {
                continue
            }
            
            if char != "," && char != "}" {
                if char == "\"" { continue }
                accumulated.append(char)
                continue
            }
            
            switch elementIdx {
                case 0:
                    symbol = .btc_usd
                    break
                case 1:
                    id = Int(accumulated)
                    break
                case 2:
                    date = Date(timeIntervalSinceReferenceDate: TimeInterval(accumulated)!)
                    break
                case 3:
                    bidQty = Double(accumulated)!
                    break
                case 4:
                    askPrice = Double(accumulated)!
                    break
                case 5:
                    bidPrice = Double(accumulated)!
                    break
                case 6:
                    askQuantity = Double(accumulated)!
                    break
                default:
                    break
            }
            
            accumulating = false
            elementIdx += 1
        }
        
        return MarketTicker(id: id, date: date, symbol: symbol.rawValue, bidPrice: bidPrice, bidQuantity: bidQty, askPrice: askPrice, askQuantity: askQuantity)
    }
}
