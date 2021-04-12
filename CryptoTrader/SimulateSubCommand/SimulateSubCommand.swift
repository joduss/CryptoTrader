import Foundation
import ArgumentParser
import JoLibrary

enum TradingStrategy : String, EnumerableFlag {
    case macd = "macd"
    case bts = "bts"
}


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
        
        @Option(name: .customShort("s"), help: "Start from")
        var startIdx: Int?
        
        @Option(name: .customShort("e"), help: "End at")
        var endIdx: Int?
        
        @Flag(exclusivity: .chooseFirst, help: "Strategy")
        var strategy: TradingStrategy
        
        @Argument
        var tickersLocation: String
        
        @Flag(help: "Double data")
        var doubleData: Bool = false
        
        // MARK: Command line main.
        // ------------------------------
        func run() throws {
            print(self)
            let simulation = try SimulateSubCommandExecution(symbol: symbol,
                                           initialBalance: initialBalance,
                                           maxOperationCount: maxOperationCount,
                                           tickersLocation: tickersLocation,
                                           tickersStartIdx: startIdx,
                                           tickersEndIdx: endIdx)
            
            simulation.execute(strategy: strategy)
        }
    }
}
