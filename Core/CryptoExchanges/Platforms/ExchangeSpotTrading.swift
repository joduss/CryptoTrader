import Foundation

protocol ExchangeSpotTrading: class {

    func listOpenOrder(completion: @escaping ([BinanceOpenOrderResponse]?) -> ())
    func cancelOrder(symbol: CryptoSymbol, id: String, newId: String?, completion: @escaping (Bool) -> ())
    func send(order: TradeOrderRequest, completion: @escaping (Bool) -> ())
}

extension ExchangeSpotTrading {
    func cancelOrder(symbol: CryptoSymbol, id: String, newId: String? = nil, completion: @escaping (Bool) -> ()) {
        return cancelOrder(symbol: symbol, id: id, newId: newId, completion: completion)
    }
}
