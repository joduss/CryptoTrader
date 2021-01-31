import Foundation
import JoLibrary

final class TradeFilesMerger: FileMerger {
    
    private let jsonDecoder = JSONDecoder()

    override init(directoryPath: String, mergedFilePath: String) {
        sourcePrint("Trades in \(directoryPath) will be merged in the file \(mergedFilePath)")
        super.init(directoryPath: directoryPath, mergedFilePath: mergedFilePath)
    }
    
    override public func objectId(inLine: String) -> Int {
        return (try! jsonDecoder.decode(MarketAggregatedTrade.self, from: inLine.data(using: .utf8)!)).id
    }  
}
