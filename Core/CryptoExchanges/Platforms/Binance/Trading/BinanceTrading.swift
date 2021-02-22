import Foundation

/// BinanceTrading is good.
final class BinanceTrading: BinanceApiFragment, ExchangeSpotTrading {
    
    private let sender: BinanceApiRequestSender
    
    override init(symbol: CryptoSymbol, config: BinanceApiConfiguration) {
        sender = BinanceApiRequestSender(config: config)
        super.init(symbol: symbol, config: config)
    }
    
    func listOpenOrder(completion: @escaping ([BinanceOrderSummaryResponse]?) -> ()) {
        let request = BinanceListOpenOrderRequest(symbol: self.symbol)
        sender.send(request, completion: {
            result in
            
            switch result {
            case let .success(response):
                completion(response)
                break
            case let .failure(error):
                sourcePrint("Error while listing open orders: \(error)")
                completion(nil)
                break
            }
        })
    }
    
    public func cancelOrder(symbol: CryptoSymbol, id: String, newId: String? = nil, completion: @escaping (Bool) -> ()) {
        let request = BinanceCancelOrderRequest(symbol: symbol, id: id, newId: newId)
        
        sender.send(request, completion: {
            result in
            switch result {
            case let .success(response):
                sourcePrint("Response: \(response)")
                completion(true)
            case let .failure(error):
                sourcePrint("Error while cancelling the request \(id) => \(error)")
                completion(false)
            }
        })
    }

    func send(order: TradeOrderRequest, completion: @escaping (Result<CreatedOrder, ExchangePlatformError>) -> ()) {
        var request = BinanceCreateOrderRequest(symbol: order.symbol,
                                                side: order.side,
                                                type: order.type,
                                                id: order.id,
                                                qty: order.quantity)
        request.price = order.price
        request.value = order.value
        
        if order.type == .stopLossLimit || order.type == .takeProfitLimit {
            if order.side == .buy {
                request.stopPrice = order.price
            }
            else {
                request.stopPrice = order.price
            }
        }
        
        sender.send(request, completion: {
            result in
            switch result {
            case let .success(response):
                completion(.success(response.toCreatedOrder()))
            case let .failure(error):
                completion(.failure(error))
            }
        })
    }
}
