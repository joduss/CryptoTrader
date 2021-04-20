import Foundation

class SimpleTrader: ExchangeMarketDataStreamSubscriber, ExchangeUserDataStreamSubscriber {

    var client: ExchangeClient
    var profits: Double = 0
    var strategy: SimpleTraderStrategy
    var printDecisionFrequency = 200


    private let updateProcessSemaphore = DispatchSemaphore(value: 1)
    private let isUpdatingVariableSemaphore = DispatchSemaphore(value: 1)
    private var decisionCount = 0
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

    init(client: ExchangeClient, strategy: SimpleTraderStrategy) {
        self.client = client
        self.strategy = strategy

        self.client.marketStream.marketDataStreamSubscriber = self
        //        self.client.userDataStream.userDataStreamSubscriber = self

        self.client.marketStream.subscribeToTickerStream()
        //        self.client.userDataStream.subscribeUserDataStream()
    }

    // MARK: - Commands
    // =================================================================
    
    func buyNow() {
        strategy.buyNow()
    }
    
    func sellAll(profits: Percent) {
        strategy.sellAll(profit: Percent(2))
    }
    
    func summary(shouldPrint: Bool) {
        strategy.summary(shouldPrint: shouldPrint)
    }

    // MARK: - Exchange events processing
    // =================================================================

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

        if printCurrentPrice && decisionCount % printDecisionFrequency == 0 {
            sourcePrint("Decision for bid price \(ticker.bidPrice) / ask price \(ticker.askPrice)")
        }

        strategy.updateTicker(bid: ticker.bidPrice, ask: ticker.askPrice)

        isUpdating = false
        updateProcessSemaphore.signal()
    }

    func process(trade: MarketAggregatedTrade) {

    }

    func process(depthUpdate: MarketDepth) {}
}
