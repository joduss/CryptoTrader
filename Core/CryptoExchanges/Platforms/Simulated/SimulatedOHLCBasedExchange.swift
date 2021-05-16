//import Foundation
//
//class SimulatedOHLCBasedExchange: ExchangeClient, ExchangeUserDataStream, ExchangeMarketDataStream,
//    ExchangeSpotTrading
//{
//    let symbol: CryptoSymbol
//
//    var marketStream: ExchangeMarketDataStream { return self }
//    var userDataStream: ExchangeUserDataStream { return self }
//    var trading: ExchangeSpotTrading { return self }
//
//    var feeRate = Percent(0.1)
//
//    private let records: ContiguousArray<OHLCRecord>
//    private let dateFactory: DateFactory
//    private var currentRecord: OHLCRecord
//    private var exchangeOrderId = 1
//    private var group = DispatchGroup()
//
//    init(symbol: CryptoSymbol, records: ContiguousArray<OHLCRecord>, dateFactory: DateFactory) {
//        self.records = records
//        self.symbol = symbol
//        self.dateFactory = dateFactory
//        currentRecord = records.first!
//
//        dateFactory.now = currentRecord.time
//    }
//
//    // ================================================================
//    // MARK: - Exchange logic
//    // ================================================================
//
//    private var orderRequests: [TradeOrderRequest] = []
//
//    func start() {
//        dateFactory.simulated = true
//
//        self.records.withUnsafeBufferPointer({ unsafeRecords in
//            for record in unsafeRecords {
//                currentRecord = record
//                onNewRecord(record)
//            }
//        })
//    }
//
//    private func onNewRecord(_ record: OHLCRecord) {
//        dateFactory.now = record.time
//        self.executeOrders(record)
//        self.marketDataStreamSubscriber?.process(trade: MarketFullAggregatedTrade(id: 0, date: record.time, symbol: symbol.rawValue, price: record.close, quantity: record.volume))
//    }
//
//    private func executeOrders(_ record: OHLCRecord) {
//        executeBuyOrders(record.close)
//        executeSellOrders(record.close)
//    }
//
//    private func executeBuyOrders(_ currencyPrice: Decimal) {
//        let orders = orderRequests.filter({ order in
//            if order.side == .sell {
//                return false
//            }
//
//            switch order.type {
//            case .market:
//                return true
//            case .limit:
//                return currencyPrice <= order.price!
//            case .stopLoss:
//                return currencyPrice >= order.price!
//            case .stopLossLimit:
//                return currencyPrice >= order.price!
//            default:
//                fatalError("\(order.type) is not a supported buy order.")
//            }
//        })
//
//        for order in orders {
//            var price: Decimal = 0.0
//
//            switch order.type {
//            case .market:
//                price = currencyPrice
//            case .limit:
//                price = order.price!  // Worst price
//            case .stopLoss:
//                price = currencyPrice
//            case .stopLossLimit:
//                price = currencyPrice
//            default:
//                fatalError("\(order.type) is not a supported buy order.")
//            }
//
//            sourcePrint("Order \(order) has been fullfiled.")
//
//            let qty: Decimal = order.quantity ?? order.value! / price
//
//            let report = OrderExecutionReport(
//                orderCreationTime: dateFactory.now,
//                symbol: symbol,
//                clientOrderId: order.id,
//                side: order.side,
//                orderType: order.type,
//                price: price,
//                currentExecutionType: .trade,
//                currentOrderStatus: .filled,
//                lastExecutedQuantity: qty,
//                cumulativeFilledQuantity: qty,
//                lastExecutedPrice: price,
//                commissionAmount: feeRate * qty * price,
//                cumulativeQuoteAssetQuantity: qty * price -% feeRate,
//                lastQuoteAssetExecutedQuantity: qty * price -% feeRate
//            )
//
//            userDataStreamSubscriber?.updated(order: report)
//
//            let idx = orderRequests.firstIndex(where: { $0.id == order.id })!
//            orderRequests.remove(at: idx)
//        }
//
//    }
//
//    private func executeSellOrders(_ currencyPrice: Decimal) {
//        let orders = orderRequests.filter({ order in
//            if order.side == .buy {
//                return false
//            }
//
//            switch order.type {
//            case .market:
//                return true
//            case .limit:
//                return currencyPrice >= order.price!
//            case .stopLoss:
//                return currencyPrice <= order.price!
//            default:
//                fatalError("\(order.type) is not a supported buy order.")
//            }
//        })
//
//        for order in orders {
//            var price: Decimal = 0.0
//
//            switch order.type {
//            case .market:
//                price = currencyPrice
//            case .limit:
//                price = order.price!  // worst price
//            case .stopLoss:
//                price = currencyPrice
//            default:
//                fatalError("\(order.type) is not a supported buy order.")
//            }
//
//            sourcePrint("Order \(order) has been fullfiled.")
//
//            guard let qty = order.quantity else {
//                fatalError("Quantity is necessary!")
//            }
//
//            let report = OrderExecutionReport(
//                orderCreationTime: dateFactory.now,
//                symbol: symbol,
//                clientOrderId: order.id,
//                side: order.side,
//                orderType: order.type,
//                price: price,
//                currentExecutionType: .trade,
//                currentOrderStatus: .filled,
//                lastExecutedQuantity: qty,
//                cumulativeFilledQuantity: qty,
//                lastExecutedPrice: price,
//                commissionAmount: Percent(0.1) * qty * price,
//                cumulativeQuoteAssetQuantity: (qty * price) -% feeRate,
//                lastQuoteAssetExecutedQuantity: qty * price -% feeRate
//            )
//
//            userDataStreamSubscriber?.updated(order: report)
//
//            let idx = orderRequests.firstIndex(where: { $0.id == order.id })!
//            orderRequests.remove(at: idx)
//        }
//    }
//
//    // ================================================================
//    // MARK: - Exchange Protocol implementation
//    // ================================================================
//
//    var webSocketHandler: WebSocketHandler = WebSocketHandler()
//
//    // MARK: - ExchangeUserDataStream
//    // ================================================================
//
//    var subscribed: Bool = false
//    var userDataStreamSubscriber: ExchangeUserDataStreamSubscriber?
//
//    func subscribeUserDataStream() {
//        subscribed = true
//    }
//
//    // MARK: - ExchangeMarketDataStream
//    // ================================================================
//
//    var marketDataStreamSubscriber: ExchangeMarketDataStreamSubscriber?
//
//    var subscribedToTickerStream: Bool = false
//    var subscribedToAggregatedTradeStream: Bool = false
//    var subscribedToMarketDepthStream: Bool = false
//
//    func subscribeToTickerStream() {
//        subscribedToTickerStream = true
//    }
//
//    func subscribeToAggregatedTradeStream() {
//        subscribedToAggregatedTradeStream = true
//    }
//
//    func subscribeToMarketDepthStream() {
//        subscribedToMarketDepthStream = true
//    }
//
//    // MARK: - ExchangeSpotTrading
//    // ================================================================
//
//    func listOpenOrder(completion: @escaping ([BinanceOrderSummaryResponse]?) -> Void) {
//
//        let responses = orderRequests.map({ order in
//            BinanceOrderSummaryResponse(
//                symbol: symbol,
//                platformOrderId: 1,
//                clientOrderId: order.id,
//                price: order.price ?? 0,
//                originalQty: order.quantity ?? 0,
//                executedQty: order.quantity ?? 0,
//                cummulativeQuoteQty: order.value ?? 0,
//                stopPrice: 0,
//                status: .new,
//                type: order.type,
//                side: order.side,
//                time: dateFactory.now,
//                updateTime: dateFactory.now,
//                originalQuoteQty: 0
//            )
//        })
//
//        completion(responses)
//    }
//
//    func cancelOrder(symbol: CryptoSymbol, id: String, newId: String?, completion: @escaping (Bool) -> Void) {
//        let idxToRemove = orderRequests.firstIndex(where: { $0.id == id })!
//
//        orderRequests.remove(at: idxToRemove)
//
//        sourcePrint("Cancelled order \(id)")
//        completion(true)
//    }
//
//    func send(order: TradeOrderRequest, completion: @escaping (Result<CreatedOrder, ExchangePlatformError>) -> Void) {
//        exchangeOrderId += 1
//
//        if order.type != .market {
//            fatalError("To be reviewed.")
////            let createdOrder = CreatedOrder(
////                symbol: order.symbol,
////                platformOrderId: exchangeOrderId,
////                clientOrderId: order.id,
////                price: order.price ?? 0,
////                originalQty: order.quantity ?? 0,
////                executedQty: 0,
////                cummulativeQuoteQty: order.value ?? 0,
////                status: .new,
////                type: order.type,
////                side: order.side,
////                time: dateFactory.now
////            )
////
////            completion(.success(createdOrder))
////
////            orderRequests.append(order)
////            sourcePrint("Created order \(order)")
////            return
//        }
//
//
//        guard order.price == nil else {
//            fatalError("Price is not a parameter for a market order.")
//        }
//
//        if let quantity = order.quantity {
//            guard order.value == nil else {
//                fatalError("Quantity and value should not both be given.")
//            }
//
//            let price = currentRecord.close
//            var value = quantity * price
//            value = order.side == .buy ? value +% Percent(0.1) : value -% Percent(0.1)
//
//            let createdOrder = CreatedOrder(
//                symbol: order.symbol,
//                platformOrderId: exchangeOrderId,
//                clientOrderId: order.id,
//                price: price,
//                originalQty: quantity,
//                executedQty: quantity,
//                cummulativeQuoteQty: value,
//                status: .filled,
//                type: order.type,
//                side: order.side,
//                time: dateFactory.now
//            )
//
//            sourcePrint("Created order \(createdOrder)")
//            completion(.success(createdOrder))
//            return
//        }
//
//        if let value = order.value {
//            guard order.quantity == nil else {
//                fatalError("Quantity and value should not both be given.")
//            }
//
//            let price = currentRecord.close
//            let qty = (value / price)
//
//
//
//            let createdOrder = CreatedOrder(
//                symbol: order.symbol,
//                platformOrderId: exchangeOrderId,
//                clientOrderId: order.id,
//                price: price,
//                originalQty: order.side == .buy ? qty -% feeRate : qty,
//                executedQty:  order.side == .buy ? qty -% feeRate : qty,
//                cummulativeQuoteQty: order.side == .buy ? value : value -% Percent(0.1),
//                status: .filled,
//                type: order.type,
//                side: order.side,
//                time: dateFactory.now
//            )
//
//            sourcePrint("Created order \(createdOrder)")
//            completion(.success(createdOrder))
//            return
//        }
//
//
//        fatalError("Not handled")
//    }
//
//}
