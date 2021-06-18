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
        
        @Option(name: .customShort("k"), help: "Keep every N data")
        var keepEvery: Int = 1
        
        @Flag(exclusivity: .chooseFirst, help: "Strategy")
        var strategy: TradingStrategy
        
        @Argument(help:"Trade data in csv or ticker file (.tickers).")
        var dataLocation: String
        
        // MARK: Command line main.
        // ------------------------------
        func run() throws {
            let gridSearch = try GridSearchSubCommandExecution(symbol: symbol,
                                                               dataLocation: dataLocation,
                                                               dataStartIdx: startIdx,
                                                               dataEndIdx: endIdx,
                                                               keepEvery: keepEvery)
            
            gridSearch.execute(strategy: strategy)
        }
    }
}
