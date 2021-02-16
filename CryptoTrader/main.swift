import Foundation
import ArgumentParser
import Cocoa
import os

let arguments = CommandLine.arguments


struct TraderMain: ParsableCommand {
    
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
//
//        binance.trading.listOpenOrder(completion: {
//            response in
//
//            print(response)
//        })
        
//        binance.trading.send(order: TradingOrderNew(symbol: .btc_usd,
//                                                    quantity: 0.001,
//                                                    price: 10000,
//                                                    side: .buy,
//                                                    type: .limit,
//                                                    id: "abcd"), completion: {
//                                                        response in
//                                                        print(response)
//                                                    })
        
        binance.trading.cancelOrder(symbol: .btc_usd, id: "my_order_id_2", newId:"fuck", completion: {
            success in
            sourcePrint("Success: \(success)")
        })
        
        sourcePrint("CryptoTrader started")
        
        switch action {
        case .trade:
            TraderMain.exit(withError: ValidationError("Trading is not yet supported"))
            break
        case .simulate:
            
            guard let aggregatedTradeRecordsPath = aggregatedTradeRecordsPath else {
                TraderMain.exit(withError: ValidationError("A path to the file containing data for simulation is required!"))
            }
            
//            DispatchQueue.global().async { [self] in
//            print("Running trader with simulation api.")
//            let api = SimulatedExchangePlatform(marketPair: self.marketPair, aggregatedTradesFilePath: aggregatedTradeRecordsPath)
//            let trader = SimulationTrader(api: api)
//            }
            break
        }
        
        var input = ""
        
        while(input != "x") {
            input = readLine() ?? ""
            
            
            if input == "x" {
                TraderMain.exit()
            }
        }
    }
}

TraderMain.main()
RunLoop.main.run()


