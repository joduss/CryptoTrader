import Foundation

struct BinanceCreateOrderRequest: BinanceApiRequest {
    typealias Response = BinanceCreateOrderAckResponse

    let security: RequestSecurity = .signed
    let method: HttpMethod = .post
    let resource = "/api/v3/order"
    
    // MARK: Order data
    
    let symbol: CryptoSymbol
    let quantity: Double
    let id: String
    let side: OrderSide
    let type: OrderType
    
    var price: Double?
    var stopPrice: Double?
    
    
    init(symbol: CryptoSymbol, side: OrderSide, type: OrderType, qty: Double, id: String) {
        self.symbol = symbol
        self.quantity = qty
        self.id = id
        self.side = side
        self.type = type
    }
    
    var queryItems: [URLQueryItem]? {
        var items = [
            URLQueryItem(name: "symbol", value: BinanceSymbolConverter.convert(symbol)),
            URLQueryItem(name: "newClientOrderId", value: id),
            URLQueryItem(name: "quantity", value: "\(quantity)"),
            URLQueryItem(name: "side", value: "\(BinanceOrderSideConverter.convert(side))"),
            URLQueryItem(name: "type", value: "\(BinanceOrderTypeConverter.convert(type: type))"),
            URLQueryItem(name: "newOrderRespType", value: "ACK")
        ]
        
        if let price = self.price, self.type != .market {
            items.append(URLQueryItem(name: "price", value: "\(price)"))
        }
        
        if let stopPrice = self.stopPrice {
            items.append(URLQueryItem(name: "stopPrice", value: "\(stopPrice)"))
        }
        
        if self.type != .market {
            items.append(URLQueryItem(name: "timeInForce", value: "GTC"))
        }
        
        return items
    }
}
