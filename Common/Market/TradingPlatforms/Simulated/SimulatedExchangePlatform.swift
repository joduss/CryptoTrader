import Foundation
import JoLibrary

public class SimulatedExchangePlatform: CryptoExchangePlatform {
    private let aggregatedTradesFilePath: String
    
    private let semaphore = DispatchSemaphore(value: 1)
    private let decoder = JSONDecoder()
    
    public private(set) var subscribedToTickerStream: Bool = false
    public private(set) var subscribedToAggregatedTradeStream: Bool = false
    public private(set) var subscribedToMarketDepthStream: Bool = false
    
    public private(set) var webSocketHandler: WebSocketHandler = WebSocketHandler(url: URL(string: "https://www.w.w")!)
    
    public private(set) var marketPair: MarketPair
    
    public var subscriber: CryptoExchangePlatformSubscriber?
    
    
    init(marketPair: MarketPair, aggregatedTradesFilePath: String) {
        self.aggregatedTradesFilePath = aggregatedTradesFilePath
        self.marketPair = marketPair
    }
    
    
    public func subscribeToTickerStream() {
        subscribedToTickerStream = true
    }
    
    public func subscribeToAggregatedTradeStream() {
        subscribedToAggregatedTradeStream = true
        
        let reader = TextFileReader.openFile(at: self.aggregatedTradesFilePath)
        
        var idx = 0
        
        while true {
            
            guard var line = reader.readLine() else {
                (subscriber as? SimpleTrader)?.summary()
                break
            }
            
            idx += 1
            
            if idx % 3 == 0 {
                continue
            }
            
            let splitLines = line[line.index(line.startIndex, offsetBy: 2)..<line.index(line.endIndex, offsetBy: -0)].split(separator: ",")
            
            let id = extractInt(startIndex: 5, in: splitLines[1])
            let qty = extractDouble(startIndex: 10, in: splitLines[0])
            let symbol = marketPair.rawValue
            let price = extractDouble(startIndex: 8, in: splitLines[3])
            let buyerIsMarker = true // don't care
            var dateLine = splitLines[5]
            dateLine.removeLast()
            dateLine.removeLast()
            let date = Date(timeIntervalSinceReferenceDate: extractDouble(startIndex: 7, in: dateLine))
            
            let trade = MarketAggregatedTrade(id: id, date: date, symbol: symbol, price: price, quantity: qty, buyerIsMaker: buyerIsMarker)
            
            //            let trade = try! decoder.decode(MarketAggregatedTrade.self, from: line.data(using: .utf8)!)
            
            self.semaphore.wait()
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                DateFactory.simulated = true
                DateFactory.now = trade.date
                self.subscriber?.process(trade: trade)
                self.semaphore.signal()
            }
        }
    }
    
    public func extractInt(startIndex: Int, in line: String.SubSequence) -> Int {
        return Int(line[line.index(line.startIndex, offsetBy: startIndex)..<line.endIndex])!
    }
    
    public func extractDouble(startIndex: Int, in line: String.SubSequence) -> Double {
        return Double(line[line.index(line.startIndex, offsetBy: startIndex)..<line.endIndex])!
    }
    
//    public func extractString(startIndex: Int, in line: String) -> String {
//        return Int(line[line.index(line.startIndex, offsetBy: offsetBy)..<line.endIndex])!
//    }
    
    public func subscribeToMarketDepthStream() {
        subscribedToMarketDepthStream = true
    }
    
    public func process(response: String) {
        
    } 
}
