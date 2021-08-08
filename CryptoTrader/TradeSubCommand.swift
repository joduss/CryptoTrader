import Foundation
import ArgumentParser

enum StrategyType: String, EnumerableFlag, CustomStringConvertible {
    case macd
    case bts
    
    public var description: String {
        return self.rawValue
    }
}

extension TraderMain {
    

    
    struct Trade: ParsableCommand {
        
        // MARK: Command line options, arguments, etc
        // ------------------------------
        
        @Flag(exclusivity: .chooseFirst, help: "The market pair.")
        var symbol: CryptoSymbol = .btc_usd

        @Option(name: .customShort("b"), help: "Initial balance available for trading.")
        var initialBalance: Double
        
        @Option(name: .customShort("c"), help: "Number of operations that can be open.")
        var maxOperationCount: Int
        
        @Argument
        var saveStateLocation: String
        
        @Flag(exclusivity: .chooseFirst, help: "Strategy to use.")
        var strategy: StrategyType
        
        // MARK: Command line main.
        // ------------------------------
        mutating func run() throws {
            let _ = TradeSubCommand(symbol: symbol,
                                    initialBalance: Double(initialBalance),
                                    maxOperationCount: maxOperationCount,
                                    saveStateLocation: saveStateLocation,
                                    strategyType: strategy)
        }
    }
}

struct TradeSubCommand {

    private let exchange: ExchangeClient!
    private var trader: SimpleTrader! = nil
    
    let symbol: CryptoSymbol
    let initialBalance: Double
    let maxOperationCount: Int?
    let saveStateLocation: String
    
    
    internal init(symbol: CryptoSymbol,
                  initialBalance: Double,
                  maxOperationCount: Int,
                  saveStateLocation: String,
                  strategyType: StrategyType) {
        
        self.symbol = symbol
        self.initialBalance = initialBalance
        self.maxOperationCount = maxOperationCount
        self.saveStateLocation = saveStateLocation
                
        exchange = BinanceClient(symbol: symbol, config: BinanceApiConfiguration(key: BinanceApiKey.apiKey, secret: BinanceApiKey.secreteKey))
        
        var strategy: SimpleTraderStrategy!
        
        switch strategyType {
            case .bts:
                strategy = createBTSStrategy(exchange: exchange)
                break
            case .macd:
                strategy = createMACDStrategy()
                break
        }

        sourcePrint("Strategy:\n \(strategy!)")
        trader = SimpleTrader(client: exchange, strategy: strategy)
        
        self.readUserInput()
    }
    
    
    func createBTSStrategy(exchange: ExchangeClient) -> SimpleTraderStrategy {
        
        var config: TraderBTSStrategyConfig!
        
        switch symbol {
            case .btc_usd:
                config = TraderBTSStrategyConfigBTC2()
                break
            case .eth_usd:
                config = TraderBTSStrategyConfigETH()
            case .icx_usd:
                config = TraderBTSStrategyConfigICX()
        }
        
        config.maxOrdersCount = maxOperationCount ?? config.maxOrdersCount
        
        return TraderBTSStrategy(exchange: exchange,
                                 config: config,
                                 initialBalance: initialBalance,
                                 currentBalance: initialBalance,
                                 saveStateLocation: saveStateLocation)
    }
    
    func createMACDStrategy() -> SimpleTraderStrategy {
        
        return TraderMACDStrategy(exchange: exchange,
                                  config: TraderMacdStrategyConfig(),
                                  initialBalance: initialBalance,
                                  currentBalance: initialBalance,
                                  saveStateLocation: saveStateLocation)
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
            trader.summary(shouldPrint: true)
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
