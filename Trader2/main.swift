import Foundation
import ArgumentParser
import Cocoa
import os

let arguments = CommandLine.arguments


struct Trader: ParsableCommand {
    
    enum Action: EnumerableFlag {
        case trade, record, simulate
    }
    
    @Flag(exclusivity: .chooseFirst, help: "The market pair.")
    var marketPair: MarketPair = .btc_usd
    
    @Flag(exclusivity: .chooseFirst, help: "What to do")
    var action: Action = .record
    
    @Argument(help: "Where to save the files for recording.")
    var recordFileDirectory: String?
    
    @Argument(help: "Base file name.")
    var fileName: String?
    
    mutating func run() throws {
        switch action {
        case .record:
            guard let directoryPath = (recordFileDirectory as NSString?)?.expandingTildeInPath else {
                Trader.exit(withError: .some(ValidationError("Giving a directory path is mandatory for action 'record'")))
            }
            
            guard let fileName = fileName else {
                Trader.exit(withError: .some(ValidationError("Giving a base file name is mandatory for action 'record'")))
            }
            
            let directoryUrl = URL(fileURLWithPath: directoryPath, isDirectory: true)
            let tickerFile = directoryUrl.appendingPathComponent("\(fileName)-tickers.json")
            let tradeFile = directoryUrl.appendingPathComponent("\(fileName)-trades.json")
            let depthFile = directoryUrl.appendingPathComponent("\(fileName)-depth.json")

            let api = Binance(marketPair: self.marketPair)
            let trader = FileMarketRecorder(api: api)
            
            trader.saveTicker(in: tickerFile)
            trader.saveAggregatedTrades(in: tradeFile)
            trader.saveDepths(in: depthFile)
            
            break
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

