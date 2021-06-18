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
        var initialBalance: Double = 200
        
        @Option(name: .customShort("s"), help: "Start from")
        var startIdx: Int?
        
        @Option(name: .customShort("e"), help: "End at")
        var endIdx: Int?
        
        @Option(name: .customShort("k"), help: "Keep every N data.")
        var keepEvery: Int = 1
        
        @Flag(exclusivity: .chooseFirst, help: "Strategy")
        var strategy: TradingStrategy
        
        @Argument(help: "Ticker file")
        var dataLocation: String
        
        // MARK: Command line main.
        // ------------------------------
        func run() throws {
            print(self)
            
            let simulation = try SimulateSubCommandExecution(symbol: symbol,
                                           initialBalance: Decimal(initialBalance),
                                           dataLocation: dataLocation,
                                           dataStartIdx: startIdx,
                                           dataEndIdx: endIdx)
            
            simulation.execute(strategy: strategy)
        }
    }
}
