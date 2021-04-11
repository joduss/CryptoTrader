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
    var time: Date
    
    init(trade: BasicMarketTrade) {
        open = trade.price
        close = trade.price
        high = trade.price
        low = trade.price
        volume = trade.quantity
        time = trade.time
        trades = 1
    }
    
    mutating func update(with trade: BasicMarketTrade) {
        
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
