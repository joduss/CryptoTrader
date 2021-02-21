import Foundation

class SimpleTrader: ExchangeMarketDataStreamSubscriber, ExchangeUserDataStreamSubscriber {
    
    var client : ExchangeClient
    
    var profits: Double = 0
    var strategy: SimpleTraderStrategy
    
    private var decisionCount = 0
    
//    private let orderSemaphore = DispatchSemaphore(1)
    private let updateProcessSemaphore = DispatchSemaphore(value: 1)
    private let isUpdatingVariableSemaphore = DispatchSemaphore(value: 1)
    private var _isUpdating = false
    
    private var isUpdating: Bool {
        get {
            isUpdatingVariableSemaphore.wait()
            let value = _isUpdating
            isUpdatingVariableSemaphore.signal()
            return value
        }
        set {
            isUpdatingVariableSemaphore.wait()
            _isUpdating = newValue
            isUpdatingVariableSemaphore.signal()
        }
    }
    
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
        updateProcessSemaphore.wait()
        isUpdating = true

        strategy.update(report: order)
        
        isUpdating = false
        updateProcessSemaphore.signal()
    }
    
    func process(ticker: MarketTicker) {
        
        if isUpdating {
            return
        }

        updateProcessSemaphore.wait()
        isUpdating = true

        decisionCount += 1
        
        if decisionCount % 200 == 0 {
            sourcePrint("Decision for bid price \(ticker.bidPrice) / ask price \(ticker.askPrice)")
        }
        
        strategy.updateBid(price: ticker.bidPrice)
        strategy.updateAsk(price: ticker.askPrice)
        
        isUpdating = false
        updateProcessSemaphore.signal()
    }
    
    func process(trade: MarketAggregatedTrade) {
        
    }
    
    func process(depthUpdate: MarketDepth) { }
}
