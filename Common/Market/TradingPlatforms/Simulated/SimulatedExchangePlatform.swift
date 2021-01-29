import Foundation
import JoLibrary

public class SimulatedExchangePlatform: CryptoExchangePlatform {
    private let aggregatedTradesFilePath: String
    
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
                
        let reader = TextFileReader.openFile(at: aggregatedTradesFilePath)
                
        while true {
            
            guard let line = reader.readLine() else {
                break
            }
            
            let trade = try! JSONDecoder().decode(MarketAggregatedTrade.self, from: line.data(using: .utf8)!)
            
            DateFactory.simulated = true
            DateFactory.now = trade.date
            subscriber?.process(trade: trade)
        }
                
    }
    
    public func subscribeToMarketDepthStream() {
        subscribedToMarketDepthStream = true
    }
    
    public func process(response: String) {
        
    } 
}
