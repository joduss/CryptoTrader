//  main.swift
//  Trader2
//
//  Created by Jonathan Duss on 09.01.21.
//

import Foundation
import ArgumentParser
import Cocoa
import os

let arguments = CommandLine.arguments

struct Trader2: ParsableCommand {
    
    enum Coin: EnumerableFlag {
        case btc, eth
    }
    
    enum Action: EnumerableFlag {
        case trade, record, simulate
    }
    
    @Flag(exclusivity: .chooseFirst, help: "The coin to trade.")
    var coin: Coin = .btc
    
    @Flag(exclusivity: .chooseFirst, help: "What to do")
    var action: Action = .record
    
    @Argument(help: "Where to save the file for recording.")
    var recordFilePath: String?
    
    mutating func run() throws {
        switch action {
        case .record:
            guard let filePath = recordFilePath else {
                print("Giving a file path is mandatory for action 'record'")
                Trader2.exit(withError: .some(ValidationError("Giving a file path is mandatory for action 'record'")))
            }
            
            sourcePrint("Running trader with Binance api.")
            let api = Kraken()
            let trader = PriceRecorder(api: api, filePath: (filePath as NSString).expandingTildeInPath)
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

Trader2.main()
RunLoop.main.run()

