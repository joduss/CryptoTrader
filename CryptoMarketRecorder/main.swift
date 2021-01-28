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
    
    @Option(name: .long)
    var loadDepthFile: String?
    
    mutating func run() throws {
        guard let directoryPath = (recordFileDirectory as NSString?)?.expandingTildeInPath else {
            CryptoMarketRecorder.exit(withError: .some(ValidationError("Giving a directory path is mandatory for action 'record'")))
        }
        
        guard let fileName = fileName else {
            CryptoMarketRecorder.exit(withError: .some(ValidationError("Giving a base file name is mandatory for action 'record'")))
        }
        
        let directoryUrl = URL(fileURLWithPath: directoryPath, isDirectory: true)
        let tickerFile = directoryUrl.appendingPathComponent("\(fileName)-tickers")
        let tradeFile = directoryUrl.appendingPathComponent("\(fileName)-trades")
        let depthFile = directoryUrl.appendingPathComponent("\(fileName)-depth")
        let depthBackupFile = directoryUrl.appendingPathComponent("\(fileName)-depth-backup.json")

        let api = Binance(marketPair: self.marketPair)
        let recorder = MarketFileRecorder(api: api, savingFrequency: 120)
        
        recorder.saveTicker(in: tickerFile)
        recorder.saveAggregatedTrades(in: tradeFile)
        
        if let loadDepthFilePath = (self.loadDepthFile as NSString?)?.expandingTildeInPath {
            recorder.loadDepthBackup(from: URL(fileURLWithPath: loadDepthFilePath))
        }
        
        recorder.saveDepths(in: depthFile)
        recorder.saveDepthBackup(in: depthBackupFile)
    }
}

CryptoMarketRecorder.main()
RunLoop.main.run()

