import Foundation


import Foundation
import JoLibrary

class OHLCDeserializer {
    
    
    class func loadOHLCAsTickers(from file: String, startIdx: Int, endIdx: Int, keepEvery: Int, symbol: CryptoSymbol) -> ContiguousArray<MarketTicker> {
        let reader = TextFileReader.openFile(at: file)
        var idx = 0
        
        var tickers = ContiguousArray<MarketTicker>()
        tickers.reserveCapacity(400000000)
        
        while true {
            
            guard let line: String = reader.readLine() else {
                break
            }
            
            idx += 1
            
            if (idx % 1000000 == 0) { print(idx) }
            if idx < startIdx { continue }
            if idx > endIdx { break }
            if (idx % keepEvery != 0) { continue }
            
            let ohlc = OHLCDeserializer.parse(line: line)
            let ticker = MarketTicker(id: idx,
                                      date: ohlc.time,
                                      symbol: symbol.description,
                                      bidPrice: ohlc.close,
                                      bidQuantity: 0,
                                      askPrice: ohlc.close,
                                      askQuantity: 0)
            tickers.append(ticker)
        }
        
        print("Deserialized \(tickers.count) by keeping a record every \(keepEvery)")
        
        return tickers
    }
    
    //price,volume,time,id
    //309.62000000,4.63086000,1502961290.346,870
    private static func parse(line: String) -> OHLCRecord {
        let values = line.substring(start: 0, end: line.count - 1).split(separator: ",")
        
        let time = Date(timeIntervalSince1970: TimeInterval(values[0])!)
        let open = Double(String(values[1]))!
        let high = Double(String(values[2]))!
        let low = Double(String(values[3]))!
        let close = Double(String(values[4]))!
        let volume = Double(String(values[5]))!
        let count = Int(String(values[6]))!

        return OHLCRecord(open: open, high: high, low: low, close: close, volume: volume, trades: count, time: time)
    }
}
