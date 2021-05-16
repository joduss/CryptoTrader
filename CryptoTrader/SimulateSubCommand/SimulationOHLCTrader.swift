//import Foundation
//
//class SimulationOHLCTrader: ExchangeMarketDataStreamSubscriber {
//    
//    var exchange: SimulatedOHLCBasedExchange
//    var profits: Double = 0
//    var strategy: SimpleTraderStrategy
//    var printDecisionFrequency = 200
//    
//    
//    private let updateProcessSemaphore = DispatchSemaphore(value: 1)
//    private let isUpdatingVariableSemaphore = DispatchSemaphore(value: 1)
//    private var decisionCount = 0
//    private var _isUpdating = false
//    
//    private var isUpdating: Bool {
//        get {
//            isUpdatingVariableSemaphore.wait()
//            let value = _isUpdating
//            isUpdatingVariableSemaphore.signal()
//            return value
//        }
//        set {
//            isUpdatingVariableSemaphore.wait()
//            _isUpdating = newValue
//            isUpdatingVariableSemaphore.signal()
//        }
//    }
//    
//    init(exchange: SimulatedOHLCBasedExchange, strategy: SimpleTraderStrategy) {
//        self.exchange = exchange
//        self.strategy = strategy
//        
//        self.exchange.marketDataStreamSubscriber  = self
//    }
//    
//    // MARK: - Commands
//    // =================================================================
//    
//    func buyNow() {
//        strategy.buyNow()
//    }
//    
//    func sellAll(profits: Percent) {
//        strategy.sellAll(profit: Percent(2))
//    }
//    
//    func summary(shouldPrint: Bool) {
//        strategy.summary(shouldPrint: shouldPrint)
//    }
//    
//    // MARK: - Exchange events processing
//    // =================================================================
//    
//    func updated(order: OrderExecutionReport) {
//        updateProcessSemaphore.wait()
//        isUpdating = true
//        
//        strategy.update(report: order)
//        
//        isUpdating = false
//        updateProcessSemaphore.signal()
//    }
//    
//    func process(ticker: MarketTicker) { }
//
//    
//    func process(trade: MarketFullAggregatedTrade) {
//        if isUpdating {
//            return
//        }
//        
//        updateProcessSemaphore.wait()
//        isUpdating = true
//        
//        decisionCount += 1
//        
//        if decisionCount % printDecisionFrequency == 0 {
//            sourcePrint("Decision for OHLC at close price \(trade.price.format(decimals: 3)).")
//        }
//        
//        strategy.updateTicker(bid: trade.price, ask: trade.price)
//        
//        isUpdating = false
//        updateProcessSemaphore.signal()
//    }
//    
//    func process(depthUpdate: MarketDepth) {}
//}
