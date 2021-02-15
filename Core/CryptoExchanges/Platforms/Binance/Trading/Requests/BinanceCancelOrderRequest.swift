import Foundation

struct BinanceCancelOrderRequest: BinanceApiRequest {
    typealias Response = BinanceCreateOrderAckResponse

    let security: BinanceRequestSecurity = .signed
    let method: HttpMethod = .delete
    let resource = "/api/v3/order"
    
    // MARK: Order data
    
    let symbol: CryptoSymbol
    let clientId: String
    let newId: String?
    
    init(symbol: CryptoSymbol, id: String, newId: String? = nil) {
        self.symbol = symbol
        self.clientId = id
        self.newId = newId
    }

    var queryItems: [URLQueryItem]? {
        var items = [
            URLQueryItem(name: "symbol", value: BinanceSymbolConverter.convert(symbol)),
            URLQueryItem(name: "origClientOrderId", value: clientId),
        ]
        
        if let newId = self.newId {
            items.append(URLQueryItem(name: "newClientOrderId", value: "\(newId)"))
        }
        
        return items
    }
}
