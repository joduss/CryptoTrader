import Foundation
import ArgumentParser
import Cocoa
import os


CryptoMarketRecorder.main()

struct CryptoMarketRecorder: ParsableCommand {
    
    static let configuration = CommandConfiguration(
        subcommands: [
            Record.self,
            Merge.self,
            Transform.self
        ]
    )
}

extension CryptoMarketRecorder {
    
    struct Record: ParsableCommand {
        
        static var configuration = CommandConfiguration(abstract: "Record the market.")
        
        @Flag(exclusivity: .chooseFirst, help: "The market pair.")
        var marketPair: CryptoSymbol = .btc_usd
        
        @Argument(help: "Where to save the files for recording.")
        var recordFileDirectory: String
        
        @Argument(help: "Base file name.")
        var fileName: String
        
        @Option(name: [.customShort("d"), .long])
        var loadDepthFile: String?
        
        mutating func run() throws {
            guard let directoryPath = (recordFileDirectory as NSString?)?.expandingTildeInPath else {
                CryptoMarketRecorder.exit(withError: .some(ValidationError("Giving a directory path is mandatory for action 'record'")))
            }
            
            // Create directory if it does not exists
            if !FileManager.default.fileExists(atPath: directoryPath) {
                try FileManager.default.createDirectory(at: URL(fileURLWithPath: directoryPath), withIntermediateDirectories: true, attributes: nil)
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

extension CryptoMarketRecorder {
    
    struct Transform: ParsableCommand {
        
        static var configuration = CommandConfiguration(abstract: "Transforming market data to ohlc in a csv.")
        
        @Argument(help: "Files where to save data.")
        var ohlcOutputFile: String
        
        @Option(name: [.customShort("t"), .long])
        var tradeCsvFile: String
        
        @Option(name: [.customShort("i"), .long], help: "What the OHLC interval. Default 60 seconds")
        var interval: TimeInterval = 60
        
        mutating func run() throws {
            print("Merge done")

            let tradeCsv = self.tradeCsvFile.expandedPath()
            let resultingFile = ohlcOutputFile.expandedPath()
            
            let transformer = MarketOHLCDataTransformer(tradesFile: tradeCsv)
            
            FileManager.default.createFile(atPath: resultingFile, contents: nil, attributes: nil)
            try transformer.transform(outputFileHandle: FileHandle(forWritingAtPath: resultingFile)!,
                                  interval: TimeInterval.fromMinutes(1))
            
            print("Merge done")
        }
    }
}
