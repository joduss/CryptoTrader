import Foundation


struct OHLCRecord {
    
/// Open - The first traded price
/// High - The highest traded price
/// Low - The lowest traded price
/// Close - The final traded price
/// Volume - The total volume traded by all trades
/// Trades - The number of individual trades}

    let open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Double
    var trades: Int
    let time: Date
    
    init(time: Date, trade: MarketMinimalAggregatedTrade) {
        self.time = time
        open = trade.price
        close = trade.price
        high = trade.price
        low = trade.price
        volume = trade.quantity
        trades = 1
    }
    
    init(time: Date, ohlc: OHLCRecord) {
        self.time = time
        open = ohlc.close
        close = ohlc.close
        high = ohlc.close
        low = ohlc.low
        volume = 0
        trades = 0
    }
    
    mutating func update(with trade: MarketMinimalAggregatedTrade) {
        
        if trade.price > high {
            high = trade.price
        }
        
        if (trade.price < low) {
            low = trade.price
        }
        
        volume += trade.quantity
        trades += 1
        close = trade.price
    }
}
