//

import Foundation

class SimulatedFullExchange: ExchangeClient, ExchangeUserDataStream, ExchangeMarketDataStream,
                             ExchangeSpotTrading
{
    let symbol: CryptoSymbol

    var marketStream: ExchangeMarketDataStream { return self }
    var userDataStream: ExchangeUserDataStream { return self }
    var trading: ExchangeSpotTrading { return self }
    
    private var currentTicker: MarketTicker
    private let tickers: [MarketTicker]
    private var exchangeOrderId = 1
    private var group = DispatchGroup()
    
    init(symbol: CryptoSymbol, tickers: [MarketTicker]) {
        self.tickers = tickers
        self.symbol = symbol
        currentTicker = tickers.first!
    }
    
    // ================================================================
    // MARK: - Exchange logic
    // ================================================================
    
    private var orderRequests: [TradeOrderRequest] = []
    
    func start() {
        DateFactory.simulated = true
        
        for ticker in tickers {
            onNewTicker(ticker)
        }
    }
    
    private func onNewTicker(_ ticker: MarketTicker) {
        DateFactory.now = ticker.date
        self.executeOrders(ticker)
        self.marketDataStreamSubscriber?.process(ticker: ticker)
    }
    
    private func executeOrders(_ ticker: MarketTicker) {
        executeBuyOrders(ticker)
        executeSellOrders(ticker)
    }
    
    private func executeBuyOrders(_ ticker: MarketTicker) {
        let orders = orderRequests.filter({ order in
            if order.side == .sell {
                return false
            }
            
            switch order.type {
            case .market:
                return true
            case .limit:
                return  ticker.askPrice <= order.price!
            case .stopLoss:
                return ticker.askPrice >= order.price!
            case .stopLossLimit:
                return ticker.askPrice >= order.price!
            default:
                fatalError("\(order.type) is not a supported buy order.")
            }
        })
                
        for order in orders {
            var price = 0.0
            
            switch order.type {
            case .market:
                price = ticker.askPrice
            case .limit:
                price = order.price! // Worst price
            case .stopLoss:
                price = ticker.askPrice
            case .stopLossLimit:
                price = ticker.askPrice
            default:
                fatalError("\(order.type) is not a supported buy order.")
            }
            
            sourcePrint("Order \(order) has been fullfiled.")
            
            let report = OrderExecutionReport(
                orderCreationTime: DateFactory.now,
                symbol: symbol,
                clientOrderId: order.id,
                side: order.side,
                orderType: order.type,
                price: price,
                currentExecutionType: .trade,
                currentOrderStatus: .filled,
                lastExecutedQuantity: order.quantity,
                cumulativeFilledQuantity: order.quantity,
                lastExecutedPrice: price,
                commissionAmount: Percent(0.1) * order.quantity * price,
                cumulativeQuoteAssetQuantity: order.quantity * price -% Percent(0.1),
                lastQuoteAssetExecutedQuantity: order.quantity * price -% Percent(0.1))
            
            userDataStreamSubscriber?.updated(order: report)
            
            let idx = orderRequests.firstIndex(where: {$0.id == order.id})!
            orderRequests.remove(at: idx)
        }
        
    }
    
    private func executeSellOrders(_ ticker: MarketTicker) {
        let orders = orderRequests.filter({ order in
            if order.side == .buy {
                return false
            }
            
            switch order.type {
            case .market:
                return true
            case .limit:
                return  ticker.bidPrice >= order.price!
            case .stopLoss:
                return ticker.bidPrice <= order.price!
            default:
                fatalError("\(order.type) is not a supported buy order.")
            }
        })
        
        for order in orders {
            var price = 0.0
            
            switch order.type {
            case .market:
                price = ticker.bidPrice
            case .limit:
                price = order.price! // worst price
            case .stopLoss:
                price = ticker.bidPrice
            default:
                fatalError("\(order.type) is not a supported buy order.")
            }
            
            sourcePrint("Order \(order) has been fullfiled.")

            let report = OrderExecutionReport(
                orderCreationTime: DateFactory.now,
                symbol: symbol,
                clientOrderId: order.id,
                side: order.side,
                orderType: order.type,
                price: price,
                currentExecutionType: .trade,
                currentOrderStatus: .filled,
                lastExecutedQuantity: order.quantity,
                cumulativeFilledQuantity: order.quantity,
                lastExecutedPrice: price,
                commissionAmount: Percent(0.1) * order.quantity * price,
                cumulativeQuoteAssetQuantity: (order.quantity * price) -% Percent(0.1),
                lastQuoteAssetExecutedQuantity: order.quantity * price -% Percent(1 - 0.1))
            
            userDataStreamSubscriber?.updated(order: report)
            
            let idx = orderRequests.firstIndex(where: {$0.id == order.id})!
            orderRequests.remove(at: idx)
        }
    }
    
    // ================================================================
    // MARK: - Exchange Protocol implementation
    // ================================================================
    
    var webSocketHandler: WebSocketHandler = WebSocketHandler()
    
    // MARK: - ExchangeUserDataStream
    // ================================================================
    
    var subscribed: Bool = false
    var userDataStreamSubscriber: ExchangeUserDataStreamSubscriber?
    
    func subscribeUserDataStream() {
        subscribed = true
    }
    
    // MARK: - ExchangeMarketDataStream
    // ================================================================
    
    var marketDataStreamSubscriber: ExchangeMarketDataStreamSubscriber?
    
    var subscribedToTickerStream: Bool = false
    var subscribedToAggregatedTradeStream: Bool = false
    var subscribedToMarketDepthStream: Bool = false
    
    func subscribeToTickerStream() {
        subscribedToTickerStream = true
    }
    
    func subscribeToAggregatedTradeStream() {
        subscribedToAggregatedTradeStream = true
    }
    
    func subscribeToMarketDepthStream() {
        subscribedToMarketDepthStream = true
    }
    
    // MARK: - ExchangeSpotTrading
    // ================================================================
    
    func listOpenOrder(completion: @escaping ([BinanceOpenOrderResponse]?) -> Void) {
        
        let responses = orderRequests.map({ order in
            BinanceOpenOrderResponse(symbol: symbol, platformOrderId: 1, clientOrderId: order.id, price: order.price ?? 0, originalQty: order.quantity, executedQty: order.quantity, cummulativeQuoteQty: order.quantity, stopPrice: 0, status: .new, type: order.type, side: order.side, time: DateFactory.now, updateTime: DateFactory.now, originalQuoteQty: 0)
        })
        
        completion(responses)
    }
    
    func cancelOrder(
        symbol: CryptoSymbol, id: String, newId: String?, completion: @escaping (Bool) -> Void
    ) {
        let idxToRemove = orderRequests.firstIndex(where: {$0.id == id})!
        
        orderRequests.remove(at: idxToRemove)
        
        sourcePrint("Cancelled order \(id)")
        completion(true)
    }
    
    func send(order: TradeOrderRequest, completion: @escaping (Bool) -> Void)
    {
        orderRequests.append(order)
        exchangeOrderId += 1
        
        sourcePrint("Created order \(order)")
        completion(true)
    }
    
}
