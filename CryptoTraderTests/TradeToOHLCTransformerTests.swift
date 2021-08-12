//

import Foundation
import XCTest
import JoLibrary

class TradeToOHLCTransformerTests: XCTestCase {
    
    func testTransformation() throws {
                    
        let bundle = Bundle(for: TradeToOHLCTransformerTests.self)
        let tradesFilePath = bundle.path(forResource: "trades-for-ohlc", ofType: "csv")!
        let expectedOutputFilePath = bundle.path(forResource: "ohlc-expected", ofType: "csv")!
        let outputPath = FileManager.default.temporaryDirectory.appendingPathComponent("output.csv").path

        if FileManager.default.fileExists(atPath: outputPath) {
            try FileManager.default.removeItem(atPath: outputPath)
        }
        
        
        let transformer = AggregatedTradeToOHLCDataTransformer(tradesFile: tradesFilePath)
        FileManager.default.createFile(atPath: outputPath, contents: nil, attributes: nil)
        
        try transformer.transform(outputFileHandle: FileHandle(forWritingAtPath: outputPath)!, aggregationInterval: TimeInterval.fromMinutes(1))
        
        let textFileReader = TextFileReader.openFile(at: outputPath)
        
        var content = ""
        var line: String? = textFileReader.readLine()
        
        repeat {
            content += line ?? ""
            line = textFileReader.readLine()
        } while(line != nil)
        
        print(content)
        
        
        
        XCTAssertEqual(5, content.split(separator: "\n").count)
        
        
        // Test if content is the same
        let fileContent = String(data: try Data(contentsOf: URL(fileURLWithPath: expectedOutputFilePath)), encoding: .utf8)!
        XCTAssertEqual(fileContent, content)
    }
}
