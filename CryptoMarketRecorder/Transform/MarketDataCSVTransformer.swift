import Foundation
import JoLibrary

///// Transforms trade data to OHLC.
///// Open - The first traded price
///// High - The highest traded price
///// Low - The lowest traded price
///// Close - The final traded price
///// Volume - The total volume traded by all trades
///// Trades - The number of individual trades
class MarketOHLCDataTransformer {
    
    private let tradesFile: String
    
    init(tradesFile: String) {
        self.tradesFile = tradesFile
    }
    
    func transform(outputFileHandle: FileHandle, interval: TimeInterval) throws {
//        outputFileHandle.write("\(Time),\"Open\",\"High\",\"Low\",\"Close\",\"Volume\",\"Trades\"\n")
        
        let reader = TextFileReader.openFile(at: tradesFile)
        var lineCount = 0
        
        var currentOhlcRecord: OHLCRecord?
        
        while let line = reader.readLine() {
            lineCount += 1
            
            let trade = deserialize(line: line)
            
            if (lineCount % 100000 == 0) {
                print("Lines processed: \(lineCount)")
            }
                        
            guard let record = currentOhlcRecord else {
                currentOhlcRecord = OHLCRecord(trade: trade)
                continue
            }

            if trade.time - record.time > interval {
                outputFileHandle.write("\(record.time.timeIntervalSince1970),\(record.open),\(record.high),\(record.low),\(record.close),\(record.volume),\(record.trades)\n")
                currentOhlcRecord = OHLCRecord(trade: trade)
                continue
            }
            
            currentOhlcRecord?.update(with: trade)
        }
        
        
        outputFileHandle.closeFile()
    }
    
    /// Deserialize a line ( "price, volume, time")
    private func deserialize(line: String) -> BasicMarketTrade {
        let values = line.trimmingCharacters(in: CharacterSet.newlines).split(separator: ",")
        
        return BasicMarketTrade(price: Double(values[0])!,
                                quantity: Double(values[1])!,
                                time: Date(timeIntervalSince1970: TimeInterval(values[2])!))
    }
}
