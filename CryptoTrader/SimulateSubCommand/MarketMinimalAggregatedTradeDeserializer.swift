import Foundation
import JoLibrary

class MarketMinimalAggregatedTradeDeserializer {
    
    class func loadTrades(from file: String, startIdx: Int, endIdx: Int) -> ContiguousArray<MarketMinimalAggregatedTrade> {
        let reader = TextFileReader.openFile(at: file)
        var idx = 0
        let keepEveryNTicker = 20
        
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
            if (idx % keepEveryNTicker != 0) { continue }
            
            let trade = MarketMinimalAggregatedTradeDeserializer.parse(line: line)
            
            trades.append(trade)
        }
        
        return trades
    }
    
    //"{"symbol":"BTCUSDT","id":8611636536,"date":634547549.01567698,"bidQuantity":186.18478599999997,"askPrice":47650.879999999997,"bidPrice":47650.870000000003,"askQuantity":2.9338730000000006}"
    private static func parse(line: String) -> MarketMinimalAggregatedTrade {
        let values = line.substring(start: 0, end: line.count - 1).split(separator: ",")
        
        return MarketMinimalAggregatedTrade(
            price: Decimal(String(values[0]))!,
            quantity: Decimal(String(values[1]))!,
            time: Date(timeIntervalSince1970: TimeInterval(values[2])!)
        )
    }
    
}
