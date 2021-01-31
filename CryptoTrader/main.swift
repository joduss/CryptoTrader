import Foundation
import ArgumentParser
import Cocoa
import os

let arguments = CommandLine.arguments


struct Trader: ParsableCommand {
    
    enum Action: EnumerableFlag {
        case trade, simulate
    }
    
    @Flag(exclusivity: .chooseFirst, help: "The market pair.")
    var marketPair: MarketPair = .btc_usd
    
    @Flag(exclusivity: .chooseFirst, help: "What to do")
    var action: Action = .simulate
    
    @Argument(help: "Where to save the files for recording.")
    var aggregatedTradeRecordsPath: String?
    
    mutating func run() throws {
        
        sourcePrint("CryptoTrader started")
        
        switch action {
        case .trade:
            Trader.exit(withError: ValidationError("Trading is not yet supported"))
            break
        case .simulate:
            
            guard let aggregatedTradeRecordsPath = aggregatedTradeRecordsPath else {
                Trader.exit(withError: ValidationError("A path to the file containing data for simulation is required!"))
            }
            
            print("Running trader with simulation api.")
            let api = SimulatedExchangePlatform(marketPair: self.marketPair, aggregatedTradesFilePath: aggregatedTradeRecordsPath)
            let trader = SimpleTrader(api: api)
            print("Total profits: \(trader.profits)")
            break
        }
    }
}

Trader.main()


