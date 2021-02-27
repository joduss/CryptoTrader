import Foundation
import ArgumentParser


extension TraderMain {
    
    struct Trade: ParsableCommand {
        
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
        
        // MARK: Command line main.
        // ------------------------------
        mutating func run() throws {
            let _ = TradeSubCommand(symbol: symbol, initialBalance: initialBalance, maxOperationCount: maxOperationCount, saveStateLocation: saveStateLocation)
        }
    }
}

struct TradeSubCommand {

    private let exchange: ExchangeClient!
    private let trader: SimpleTrader!
    
    let symbol: CryptoSymbol
    let initialBalance: Double
    let maxOperationCount: Int
    let saveStateLocation: String
    
    
    internal init(symbol: CryptoSymbol, initialBalance: Double, maxOperationCount: Int, saveStateLocation: String) {
        
        self.symbol = symbol
        self.initialBalance = initialBalance
        self.maxOperationCount = maxOperationCount
        self.saveStateLocation = saveStateLocation
        
        exchange = BinanceClient(symbol: symbol, config: BinanceApiConfiguration(key: BinanceApiKey.apiKey, secret: BinanceApiKey.secreteKey))
        let config = TraderBTSStrategyConfiguration(maxOrdersCount: maxOperationCount)
        let strategy = SimpleTraderBTSStrategy(exchange: exchange,
                                               config: config,
                                               initialBalance: initialBalance,
                                               currentBalance: initialBalance,
                                               saveStateLocation: saveStateLocation)
        trader = SimpleTrader(client: exchange, strategy: strategy)
        
        self.readUserInput()
    }
    
    func readUserInput() {
        DispatchQueue(label: "user-input").async {
            while (true) {
                if let input = readLine() {
                    parseInput(input: input)
                }
            }
        }
    }
    
    func parseInput(input: String) {
        if input.starts(with: "exit") {
            TraderMain.exit()
        }
        
        if input.starts(with: "buy") {
            trader.buyNow()
            return
        }
        
        if input.starts(with: "sell-all") {
            let profits = input.replacingOccurrences(of: "sell-all", with: "")
            
            if let profitNumber = Double(profits) {
                trader.sellAll(profits: Percent(profitNumber))
            }
            else {
                printUsage()
                return
            }
        }
        
        if input.starts(with: "summary") {
            trader.summary()
            return
        }
        
        // Unknown
        printUsage()
    }
    
    func printUsage() {
        print(
            """
            Available inline commands:
            - exit
            - buy
            - sell-all XX.X
            - summary
            """
        )
    }
}
