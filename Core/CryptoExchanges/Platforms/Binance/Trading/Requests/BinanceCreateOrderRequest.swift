import Foundation

struct BinanceCreateOrderRequest: BinanceApiRequest {
    typealias Response = BinanceCreateOrderFullResponse

    let security: BinanceRequestSecurity = .signed
    let method: HttpMethod = .post
    let resource = "/api/v3/order"
    
    // MARK: Order data
    
    let symbol: CryptoSymbol
    let quantity: Decimal?
    let id: String
    let side: OrderSide
    let type: OrderType
    
    var value: Decimal?
    var price: Decimal?
    var stopPrice: Decimal?
    
    
    init(symbol: CryptoSymbol, side: OrderSide, type: OrderType, id: String,
         qty: Decimal? = nil, price: Decimal? = nil, value: Decimal? = nil) {
        self.symbol = symbol
        self.quantity = qty
        self.id = id
        self.side = side
        self.type = type
    }
    
    var queryItems: [URLQueryItem]? {
        
        let qtyFormatter = NumberFormatter()
        qtyFormatter.maximumFractionDigits = 8
        
        let priceFormatter = NumberFormatter()
        priceFormatter.maximumFractionDigits = 2
        
        var items = [
            URLQueryItem(name: "symbol", value: BinanceSymbolConverter.convert(symbol)),
            URLQueryItem(name: "newClientOrderId", value: id),
            URLQueryItem(name: "side", value: "\(BinanceOrderSideConverter.convert(side))"),
            URLQueryItem(name: "type", value: "\(BinanceOrderTypeConverter.convert(type: type))"),
            URLQueryItem(name: "newOrderRespType", value: "FULL")
        ]
        
        if let price = self.price, self.type != .market {
            items.append(URLQueryItem(name: "price", value: priceFormatter.string(from: price)))
        }
        
        if let quantity = self.quantity {
            items.append(URLQueryItem(name: "quantity", value: qtyFormatter.string(from: quantity)))
        }
        
        if let value = self.value {
            items.append(URLQueryItem(name: "quoteOrderQty", value: qtyFormatter.string(from: value)))
        }
        
        if let stopPrice = self.stopPrice {
            items.append(URLQueryItem(name: "stopPrice", value: priceFormatter.string(from: stopPrice)))
        }
        
        if self.type != .market {
            items.append(URLQueryItem(name: "timeInForce", value: "GTC"))
        }
        
        return items
    }
}
