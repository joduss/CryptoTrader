import Foundation

protocol ExchangeSpotTrading: AnyObject {

    func listOpenOrder(completion: @escaping ([BinanceOrderSummaryResponse]?) -> ())
    func cancelOrder(symbol: CryptoSymbol, id: String, newId: String?, completion: @escaping (Bool) -> ())
    func send(order: TradeOrderRequest, completion: @escaping (Result<CreatedOrder, ExchangePlatformError>) -> ())
}

extension ExchangeSpotTrading {
    func cancelOrder(symbol: CryptoSymbol, id: String, newId: String? = nil, completion: @escaping (Bool) -> ()) {
        return cancelOrder(symbol: symbol, id: id, newId: newId, completion: completion)
    }
}
