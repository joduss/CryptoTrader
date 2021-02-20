import Foundation

class SimpleTrader: ExchangeMarketDataStreamSubscriber, ExchangeUserDataStreamSubscriber {
    
    var client : ExchangeClient
    
    var profits: Double = 0
    var strategy: SimpleTraderStrategy
    
    private var decisionCount = 0

    
    init(client: ExchangeClient, initialBalance: Double, currentBalance: Double, maxOrderCount: Int) {
        self.client = client
        
        var config = SimpleTraderStrategyConfiguration()
        config.maxOrdersCount = maxOrderCount
        
        self.strategy = SimpleTraderBTSStrategy(exchange: client,
                                                config: config,
                                                initialBalance: initialBalance,
                                                currentBalance: currentBalance)
        
        
        self.client.marketStream.marketDataStreamSubscriber = self
        self.client.userDataStream.userDataStreamSubscriber = self
        
        self.client.marketStream.subscribeToTickerStream()
        self.client.userDataStream.subscribeUserDataStream()
    }
    
    func updated(order: OrderExecutionReport) {
        strategy.update(report: order)
    }
    
    func process(ticker: MarketTicker) {
        decisionCount += 1
        
        if decisionCount % 200 == 0 {
            sourcePrint("Decision for bid price \(ticker.bidPrice) / ask price \(ticker.askPrice)")
        }
        
        strategy.updateBid(price: ticker.bidPrice)
        strategy.updateAsk(price: ticker.askPrice)
    }
    
    func process(trade: MarketAggregatedTrade) {
    }
    
    func process(depthUpdate: MarketDepth) { }
}
