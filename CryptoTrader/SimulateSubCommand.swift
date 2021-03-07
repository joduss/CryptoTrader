import Foundation
import ArgumentParser
import JoLibrary

extension TraderMain {
    
    struct Simulate: ParsableCommand {
        
        // MARK: Command line options, arguments, etc
        // ------------------------------
        
        @Flag(exclusivity: .chooseFirst, help: "The market pair.")
        var symbol: CryptoSymbol = .btc_usd
        
        @Option(name: .customShort("b"), help: "Initial balance available for trading.")
        var initialBalance: Double
        
        @Option(name: .customShort("c"), help: "Number of operation that can be open.")
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

struct SimulateSubCommand {
    
    let symbol: CryptoSymbol
    let initialBalance: Double
    let maxOperationCount: Int
    let saveStateLocation: String
    
    let tickers: [MarketTicker]
    
    
    internal init(symbol: CryptoSymbol, initialBalance: Double, maxOperationCount: Int, saveStateLocation: String, tickersLocation: String, gridSearch: Bool) throws {
        
        let reader = TextFileReader.openFile(at: tickersLocation)
        var idx = 0
        let keepEveryNTicker = 10
        
        var tickersRead = [MarketTicker]()
        tickersRead.reserveCapacity(50000000)
        
        while true {
            
            guard let line = reader.readLine() else {
                break
            }
            
            idx += 1
            
            if (idx % 1000000 == 0) { print(idx) }
            if idx < 26000000 { continue }
//            if idx > 5000000 { break }
            if (idx % keepEveryNTicker != 0) { continue }

            let ticker = SimulateSubCommand.parse(line: line)
            
            
            let startDate: Date = Date(timeIntervalSinceReferenceDate: 635846400)
            let endDate: Date = Date()
                
            
            if ticker.date < startDate {
                continue
            }
            
            if ticker.date > endDate {
                break
            }
            
            tickers.append(ticker)
            tickersRead.append(ticker)
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
        
        var config = TraderBTSStrategyConfiguration(maxOrdersCount: maxOperationCount)
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
        sourcePriceHidden = true

        var results: [(Double, String)] = []
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 12
        
        for maxOrder in [10, 15] {
            for buyStopLossPercent in [0.1, 0.23, 0.5, 0.7, 1] {
                for sellStopLossProfitPercent in [0.1, 0.3, 0.5, 0.75, 1] {
                    for minDistancePercentNegative in [-1.5, -1.2, -0.8, -0.5] {
                        for minDistancePercentPositive in [0.1, 0.25, 0.5, 0.75, 1] {
                            for nextBuyTargetPercent in [0.1, 0.25, 0.5] {
                                for nextBuyTargetExpiration in [30, 60, 120] {
                                    var config = TraderBTSStrategyConfiguration()
                                    config.maxOrdersCount = maxOrder
                                    config.buyStopLossPercent = Percent(buyStopLossPercent)
                                    config.sellStopLossProfitPercent = Percent(sellStopLossProfitPercent)
                                    config.minSellStopLossProfitPercent = Percent(sellStopLossProfitPercent)
                                    config.minDistancePercentPositive = Percent(minDistancePercentPositive)
                                    config.minDistancePercentNegative = Percent(minDistancePercentNegative)
                                    config.nextBuyTargetPercent = Percent(nextBuyTargetPercent)
                                    config.nextBuyTargetExpiration = TimeInterval.fromMinutes(Double(nextBuyTargetExpiration))
                                                                        
                                    queue.addOperation {
                                        let simulationResults = simulate(config: config)
                                        
                                        testSema.wait()
                                        results.append(simulationResults)
                                        print("Progress: \(queue.progress.completedUnitCount) / \(queue.progress.totalUnitCount) (\(queue.progress.fractionCompleted * 100)%)")
                                        testSema.signal()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        queue.progress.totalUnitCount = Int64(queue.operationCount)
        
//        results.map({r in "########################################" + r.1 + "\(r.0)\n\n\n---------------------------------------------------------------------------"}).joined(separator: "\n").data(using: .utf8)?.write(to: URL(fileURLWithPath: "/Users/jonathanduss/Downloads/2/a4.txt"))
        
        queue.waitUntilAllOperationsAreFinished()
        print(results)
    }
    
    private func simulate(config: TraderBTSStrategyConfiguration, dateFactory: DateFactory, printPrice: Bool = false) -> (Double, String) {
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

            \(strategy.summary())
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
//        var charIdx = 0
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
