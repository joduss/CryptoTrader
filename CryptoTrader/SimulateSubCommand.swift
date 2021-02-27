import Foundation
import ArgumentParser
import JoLibrary
import ZippyJSON

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
        
        // MARK: Command line main.
        // ------------------------------
        func run() throws {
            let _ = try SimulateSubCommand(symbol: symbol, initialBalance: initialBalance, maxOperationCount: maxOperationCount, saveStateLocation: saveStateLocation, tickersLocation: tickersLocation)
        }
    }
}

struct SimulateSubCommand {
    
    private let exchange: SimulatedFullExchange!
    private let trader: SimpleTrader!
    
    let symbol: CryptoSymbol
    let initialBalance: Double
    let maxOperationCount: Int
    let saveStateLocation: String
    
    
    internal init(symbol: CryptoSymbol, initialBalance: Double, maxOperationCount: Int, saveStateLocation: String, tickersLocation: String) throws {
        
        let reader = TextFileReader.openFile(at: tickersLocation)
        var idx = 0
        let keepEveryNTicker = 5
        
        let jsonDecoder = JSONDecoder()
        var tickers = [MarketTicker]()
        tickers.reserveCapacity(30000000)
        
        while true {
            
            guard let line = reader.readLine() else {
                break
            }
            
            idx += 1
            
            if (idx % 1000000 == 0) { print(idx) }
            if idx < 26000000 { continue }
//            if idx > 5000000 { break }
            if (idx % keepEveryNTicker != 0) { continue }
            
            var ticker: MarketTicker!
            try autoreleasepool {
                let data = line.data(using: .utf8)!
                ticker = try jsonDecoder.decode(MarketTicker.self, from: data)
            }
            
            let startDate: Date = Date(timeIntervalSinceReferenceDate: 635846400)
            let endDate: Date = Date()
                
            
            if ticker.date < startDate {
                continue
            }
            
            if ticker.date > endDate {
                break
            }
            
            tickers.append(ticker)
        }
        
        self.symbol = symbol
        self.initialBalance = initialBalance
        self.maxOperationCount = maxOperationCount
        self.saveStateLocation = saveStateLocation
        
        exchange = SimulatedFullExchange(symbol: symbol, tickers: tickers)
        let config = TraderBTSStrategyConfiguration(maxOrdersCount: maxOperationCount)
        let strategy = SimpleTraderBTSStrategy(exchange: exchange,
                                               config: config,
                                               initialBalance: initialBalance,
                                               currentBalance: initialBalance,
                                               saveStateLocation: saveStateLocation)
        strategy.saveEnabled = false
        trader = SimpleTrader(client: exchange, strategy: strategy)
        exchange.start()
        
        strategy.summary()
    }
}
