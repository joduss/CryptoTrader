import Foundation

public protocol ExchangeMarketDataStreamSubscriber: AnyObject {
    func process(ticker: MarketTicker)
    func process(trade: MarketFullAggregatedTrade)
    func process(depthUpdate: MarketDepth)
}

public protocol ExchangeMarketDataStream: AnyObject {
    var subscribedToTickerStream: Bool { get }
    var subscribedToAggregatedTradeStream: Bool { get }
    var subscribedToMarketDepthStream: Bool { get }

    var webSocketHandler: WebSocketHandler { get }
    var symbol: CryptoSymbol { get }
    var marketDataStreamSubscriber: ExchangeMarketDataStreamSubscriber? { get set }
    
    func subscribeToTickerStream()
    func subscribeToAggregatedTradeStream()
    func subscribeToMarketDepthStream()
}

extension ExchangeMarketDataStream {
    
    func resubscribe() {
        if subscribedToTickerStream {
            self.subscribeToTickerStream()
        }
        
        if subscribedToAggregatedTradeStream {
            self.subscribeToAggregatedTradeStream()
        }
        
        if subscribedToMarketDepthStream {
            self.subscribeToMarketDepthStream()
        }
    }
    
    func recreateSocket() {
        webSocketHandler.createSocket { success in
            if success {
                self.resubscribe()
            }
            else {
                sourcePrint("Re-creating the socket failed... trying again in 10 seconds...")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: { [weak self] in
                    self?.recreateSocket()
                })
            }
        }
    }
    
    public func error() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 15) {
            sourcePrint("Websocket connection did encounter an error...")
            self.recreateSocket()
        }
    }
    
    public func didClose() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 15) {
            sourcePrint("Websocket connection did close...")
            self.recreateSocket()
        }
    }
}


