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
    
    public func cancelOrder(_ id: String) {
        
    }

    func send(order: TradingOrder, completion: () -> ()) {
        // If Response => "{"code":" => Error
    }
}
