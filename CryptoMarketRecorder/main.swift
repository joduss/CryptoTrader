import Foundation
import ArgumentParser
import Cocoa
import os

struct CryptoMarketRecorder: ParsableCommand {
    
    @Flag(exclusivity: .chooseFirst, help: "The market pair.")
    var marketPair: MarketPair = .btc_usd
    
    @Argument(help: "Where to save the files for recording.")
    var recordFileDirectory: String?
    
    @Argument(help: "Base file name.")
    var fileName: String?
    
    mutating func run() throws {
        guard let directoryPath = (recordFileDirectory as NSString?)?.expandingTildeInPath else {
            CryptoMarketRecorder.exit(withError: .some(ValidationError("Giving a directory path is mandatory for action 'record'")))
        }
        
        guard let fileName = fileName else {
            CryptoMarketRecorder.exit(withError: .some(ValidationError("Giving a base file name is mandatory for action 'record'")))
        }
        
        let directoryUrl = URL(fileURLWithPath: directoryPath, isDirectory: true)
        let tickerFile = directoryUrl.appendingPathComponent("\(fileName)-tickers.json")
        let tradeFile = directoryUrl.appendingPathComponent("\(fileName)-trades.json")
        let depthFile = directoryUrl.appendingPathComponent("\(fileName)-depth.json")
        
        let api = Binance(marketPair: self.marketPair)
        let recorder = MarketFileRecorder(api: api, savingFrequency: 5000)
        
        
        recorder.saveTicker(in: tickerFile)
        recorder.saveAggregatedTrades(in: tradeFile)
        recorder.saveDepths(in: depthFile)
    }
}

CryptoMarketRecorder.main()
RunLoop.main.run()

