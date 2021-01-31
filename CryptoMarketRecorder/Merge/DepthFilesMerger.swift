import Foundation
import JoLibrary
import ArgumentParser

final class DepthFilesMerger: FileMerger {
    
    private let jsonDecoder = JSONDecoder()

    override init(directoryPath: String, mergedFilePath: String) {
        sourcePrint("Depths in \(directoryPath) will be merged in the file \(mergedFilePath)")
        super.init(directoryPath: directoryPath, mergedFilePath: mergedFilePath)
    }
    
    override public func objectId(inLine line: String) throws -> Int {
        
        guard let id = (try? jsonDecoder.decode(MarketDepth.self, from: line.data(using: .utf8)!))?.id else {
            sourcePrint("Cannot decode json of type 'MarketDepth' from line \(line)")
            throw ExitCode.failure
        }
        
        return id
    }
}
