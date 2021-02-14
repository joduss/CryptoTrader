import Foundation

struct BinanceListOpenOrderRequest: BinanceApiRequest {
    typealias Response = [BinanceOpenOrderResponse]
    
    let security: RequestSecurity = .signed
    let method: HttpMethod = .get
    let resource = "/api/v3/openOrders"
    
    private(set) var queryItems: [URLQueryItem]?
    
    
    init(symbol: CryptoSymbol) {
        self.queryItems = [
            URLQueryItem(name: "symbol", value: BinanceSymbolConverter.convert(symbol))
        ]
    }
}
