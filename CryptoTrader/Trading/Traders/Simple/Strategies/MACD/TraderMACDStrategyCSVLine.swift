import Foundation

struct TraderMACDStrategyCSVLine {
    
    let file: FileHandle
    
    var date: Date
    var bidPrice: Double
    var buy: Double?
    var sell: Double?
    var macd: Double? = 0
    var signal: Double? = 0
    
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
