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
    var recordFileDirectory: String?
    
    @Argument(help: "Base file name.")
    var fileName: String?
    
    mutating func run() throws {
        switch action {
        case .trade:
            sourcePrint("Trading is not yet supported.")
            break
        case .simulate:
            //print("Running trader with simulation api.")
            //let api = SimulatedTradingPlatform(prices: prices)
            //let trader = Trader(api: api)
            //api.startSimulation(completed: {
            //    print("Total profits: \(trader.profits)")
            //})
            break
        }
        
    }
}

Trader.main()
RunLoop.main.run()

