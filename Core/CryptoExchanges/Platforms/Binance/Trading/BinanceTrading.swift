import Foundation

final class BinanceTrading: BinanceApiFragment {
    
    private let sender: BinanceApiRequestSender
    
    override init(symbol: CryptoSymbol, config: BinanceApiConfiguration) {
        sender = BinanceApiRequestSender(config: config)
        super.init(symbol: symbol, config: config)
    }
    
    func listOpenOrder(completion: @escaping ([BinanceOpenOrderResponse]?) -> ()) {
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
        var request = BinanceCancelOrderRequest(symbol: symbol, id: id, newId: newId)
        
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

    func send(order: TradeOrderRequest, completion: @escaping (BinanceCreateOrderAckResponse) -> ()) {
        var request = BinanceCreateOrderRequest(symbol: order.symbol,
                                                side: order.side,
                                                type: order.type,
                                                qty: order.quantity,
                                                id: order.id)
        request.price = order.price
        
        sender.send(request, completion: {
            result in
            switch result {
            case let .success(response):
                completion(response)
            case let .failure(error):
                print("Failed to create a new order. \(error)")
            }
        })
    }
}
