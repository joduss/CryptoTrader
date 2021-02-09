import Foundation
import ArgumentParser
import Cocoa
import os


CryptoMarketRecorder.main()

struct CryptoMarketRecorder: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        subcommands: [
            Record.self,
            Merge.self
        ]
    )
}

extension CryptoMarketRecorder {
    
    struct Record: ParsableCommand {
        
        static var configuration = CommandConfiguration(abstract: "Record the market.")
        
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
            let tickerFile = directoryUrl.appendingPathComponent("\(fileName).tickers")
            let tradeFile = directoryUrl.appendingPathComponent("\(fileName).trades")
            let depthFile = directoryUrl.appendingPathComponent("\(fileName).depths")
            let depthBackupFile = directoryUrl.appendingPathComponent("\(fileName)-depth-backup.json")
            
            var api: BinanceMarketStream!
            let apiConfig = BinanceApiConfiguration(key: BinanceApiKey.apiKey, secret: BinanceApiKey.secreteKey)
            
            if let loadDepthFilePath = (self.loadDepthFile as NSString?)?.expandingTildeInPath {
                sourcePrint("Loading depths backup from \(loadDepthFilePath)...")
                let data = try! Data(contentsOf: URL(fileURLWithPath: loadDepthFilePath))
                let backup = try! JSONDecoder().decode(MarketDepthBackup.self, from: data)
                api = BinanceMarketStream(symbol: marketPair, config: apiConfig, marketDepthBackup: backup)
            }
            else {
                api = BinanceMarketStream(symbol: self.marketPair, config: apiConfig)
            }

            let recorder = MarketFileRecorder(api: api, savingFrequency: 5000)
            
            recorder.saveDepthBackup(in: depthBackupFile)
            recorder.saveTicker(in: tickerFile)
            recorder.saveAggregatedTrades(in: tradeFile)
            recorder.saveDepths(in: depthFile)
            
            RunLoop.main.run()
        }
    }
}


/// This exntension ads a subcommand to merge files together.
extension CryptoMarketRecorder {
    
    struct Merge: ParsableCommand {
        
        static var configuration = CommandConfiguration(abstract: "Merge files containing market data.")
        
        @Option(name: .shortAndLong)
        var fileToMergeDirectory: String?
        
        @Argument(help: "Directory where to save the resulting files.")
        var resultsDirectory: String

        mutating func run() throws {
            
            let resultDirectoryPath = resultsDirectory.expandedPath() as NSString
                        
            if let depthFilesDirectory = self.fileToMergeDirectory?.expandedPath() {
                let resultingFile = resultDirectoryPath.appendingPathComponent("merged.depths")
                let merger = DepthFilesMerger(directoryPath: depthFilesDirectory, mergedFilePath: resultingFile)
                try merger.merge()
            }
            
            if let tradeFilesDirectory = self.fileToMergeDirectory?.expandedPath() {
                let resultingFile = resultDirectoryPath.appendingPathComponent("merged.trades")
                let merger = TradeFilesMerger(directoryPath: tradeFilesDirectory, mergedFilePath: resultingFile)
                try merger.merge()
            }
            
            if let tickerFilesDirectory = self.fileToMergeDirectory?.expandedPath() {
                let resultingFile = resultDirectoryPath.appendingPathComponent("merged.tickers")
                let merger = TickerFilesMerger(directoryPath: tickerFilesDirectory, mergedFilePath: resultingFile)
                try merger.merge()
            }
            
            print("Merge done")
        }
    }
}

