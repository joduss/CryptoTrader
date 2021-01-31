import Foundation
import JoLibrary

final class TickerFilesMerger: FileMerger {
    
    private let jsonDecoder = JSONDecoder()

    override init(directoryPath: String, mergedFilePath: String) {
        sourcePrint("Tickers in \(directoryPath) will be merged in the file \(mergedFilePath)")
        super.init(directoryPath: directoryPath, mergedFilePath: mergedFilePath)
    }
    
    override public func objectId(inLine: String) -> Int {
        return (try! jsonDecoder.decode(MarketTicker.self, from: inLine.data(using: .utf8)!)).id
    }  
}
