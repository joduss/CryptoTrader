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
