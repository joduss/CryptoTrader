import Foundation
import ArgumentParser

final class TickerFilesMerger: FileMerger {
    
    private let jsonDecoder = JSONDecoder()

    override init(directoryPath: String, mergedFilePath: String) {
        sourcePrint("Tickers in \(directoryPath) will be merged in the file \(mergedFilePath)")
        super.init(directoryPath: directoryPath, mergedFilePath: mergedFilePath)
    }
    
    override public func objectId(inLine line: String) throws -> Int {
        guard let id = (try? jsonDecoder.decode(MarketTicker.self, from: line.data(using: .utf8)!))?.id else {
            sourcePrint("Cannot decode json of type 'MarketTicker' from line \(line)")
            throw ExitCode.failure
        }
        
        return id
    }
}
