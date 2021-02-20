import Foundation

class SimpleTrader: ExchangeMarketDataStreamSubscriber, ExchangeUserDataStreamSubscriber {

    
    
    var api : BinanceClient
    
    var profits: Double = 0
    var strategy: SimpleTraderStrategy
    
    private var decisionCount = 0

    
    init(client: BinanceClient, initialBalance: Double, currentBalance: Double, maxOrderCount: Int) {
        self.api = client
//        self.api.marketStream.subscribeToTickerStream()
        self.api.marketStream.subscribeToAggregatedTradeStream()
        
        var config = SimpleTraderStrategyConfiguration()
        config.maxOrdersCount = maxOrderCount
        
        self.strategy = SimpleTraderBTSStrategy(symbol: client.symbol,
                                                        config: config,
                                                        initialBalance: initialBalance,
                                                        currentBalance: currentBalance)
        
        
        self.api.marketStream.marketDataStreamSubscriber = self
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
