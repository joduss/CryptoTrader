import Foundation

struct BinanceListOpenOrderRequest: BinanceApiRequest {
    typealias Response = [BinanceOrderSummaryResponse]
    
    let security: BinanceRequestSecurity = .signed
    let method: HttpMethod = .get
    let resource = "/api/v3/openOrders"
    
    private(set) var queryItems: [URLQueryItem]?
    
    
    init(symbol: CryptoSymbol) {
        self.queryItems = [
            URLQueryItem(name: "symbol", value: BinanceSymbolConverter.convert(symbol))
        ]
    }
}
