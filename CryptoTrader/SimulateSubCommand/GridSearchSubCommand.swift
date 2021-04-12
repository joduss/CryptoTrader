import Foundation
import ArgumentParser

extension TraderMain {
    
    struct GridSearch: ParsableCommand {
        
        // MARK: Command line options, arguments, etc
        // ------------------------------
        
        @Flag(exclusivity: .chooseFirst, help: "The market pair.")
        var symbol: CryptoSymbol = .btc_usd
        
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
            let gridSearch = try GridSearchSubCommandExecution(symbol: symbol,
                                                               tickersLocation: tickersLocation,
                                                               tickersStartIdx: startIdx,
                                                               tickersEndIdx: endIdx)
            
            gridSearch.execute(strategy: strategy)
        }
    }
}
