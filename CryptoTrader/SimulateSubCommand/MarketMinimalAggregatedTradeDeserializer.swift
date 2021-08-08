import Foundation
import JoLibrary

class MarketMinimalAggregatedTradeDeserializer {
    
    class func loadTrades(from file: String, startIdx: Int, endIdx: Int, keepEvery: Int) -> ContiguousArray<MarketMinimalAggregatedTrade> {
        let reader = TextFileReader.openFile(at: file)
        var idx = 0
        
        var trades = ContiguousArray<MarketMinimalAggregatedTrade>()
        trades.reserveCapacity(400000000)
        
        while true {
            
            guard let line: String = reader.readLine() else {
                break
            }
            
            idx += 1
            
            if (idx % 1000000 == 0) { print(idx) }
            if idx < startIdx { continue }
            if idx > endIdx { break }
            if (idx % keepEvery != 0) { continue }
            
            let trade = MarketMinimalAggregatedTradeDeserializer.parse(line: line)
            
            trades.append(trade)
        }
        
        return trades
    }
    
    class func loadTradesAsTickers(from file: String, startIdx: Int, endIdx: Int, keepEvery: Int, symbol: CryptoSymbol) -> ContiguousArray<MarketTicker>{
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

            let ticker = MarketMinimalAggregatedTradeDeserializer.parse(line: line, symbol: symbol)
            
            tickers.append(ticker)
        }
        
        print("Deserialized \(tickers.count) by keeping a record every \(keepEvery)")
        
        return tickers
    }
    
    //price,volume,time,id
    //309.62000000,4.63086000,1502961290.346,870
    private static func parse(line: String) -> MarketMinimalAggregatedTrade {
        let values = line.substring(start: 0, end: line.count - 1).split(separator: ",")
        
        return MarketMinimalAggregatedTrade(
            price: Double(String(values[0]))!,
            quantity: Double(String(values[1]))!,
            time: Date(timeIntervalSince1970: TimeInterval(values[2])!)
        )
    }
    
    //price,volume,time,id
    //309.62000000,4.63086000,1502961290.346,870
    private static func parse(line: String, symbol: CryptoSymbol) -> MarketTicker {
        let values = line.substring(start: 0, end: line.count - 1).split(separator: ",")
        
        let price = Double(String(values[0]))!
        let qty = Double(String(values[1]))!
        let time = Date(timeIntervalSince1970: TimeInterval(values[2])!)
        
        return MarketTicker(id: Int(values[3])!,
                            date: time,
                            symbol: symbol.rawValue,
                            bidPrice: price,
                            bidQuantity: qty,
                            askPrice: price,
                            askQuantity: qty)
    }
}
