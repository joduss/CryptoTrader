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
    var marketPair: CryptoSymbol = .btc_usd
    
    @Flag(exclusivity: .chooseFirst, help: "What to do")
    var action: Action = .simulate
    
    @Argument(help: "Where to save the files for recording.")
    var aggregatedTradeRecordsPath: String?
    
    mutating func run() throws {
        
        let config = BinanceApiConfiguration(key: BinanceTestApiKeys.apiKey, secret: BinanceTestApiKeys.secreteKey)
        config.demo = true
//        let b = BinanceUserDataStream(symbol: marketPair, config: config)
//        b.subscribe()
        
        let binance = BinanceClient(symbol: marketPair, config: config)
        
        binance.trading.listOpenOrder(completion: {
            response in
            
            print(response)
        })
        
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
//            let api = SimulatedExchangePlatform(marketPair: self.marketPair, aggregatedTradesFilePath: aggregatedTradeRecordsPath)
//            let trader = SimpleTrader(api: api)
            break
        }
    }
}

Trader.main()
RunLoop.main.run()


