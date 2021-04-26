import Foundation

struct TraderMACDStrategyCSVLine {
    
    let file: FileHandle
    
    var date: Date
    var bidPrice: Decimal
    var buy: Decimal?
    var sell: Decimal?
    var macd: Decimal? = 0
    var signal: Decimal? = 0
    
    mutating func reset() {
        buy = nil
        sell = nil
    }
    
    func writeHeader() {
        file.write("date,bid,buy,sell,macd,signal\n")
    }
    
    func write() {
        file.write("\(date.timeIntervalSince1970),\(bidPrice),\(buy?.description ?? ""),\(sell?.description ?? ""),\(macd?.description ?? ""),\(signal?.description ?? "")\n")
    }
}
