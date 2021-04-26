import Foundation

struct TradeOrderRequest: CustomStringConvertible {
    
    let symbol: CryptoSymbol
    var quantity: Decimal?
    var price: Decimal?
    var value: Decimal?
    let side: OrderSide
    let type: OrderType
    let id: String
    
    internal init(symbol: CryptoSymbol, quantity: Decimal? = nil, price: Decimal? = nil, value: Decimal? = nil, side: OrderSide, type: OrderType, id: String) {
        self.symbol = symbol
        self.quantity = quantity
        self.price = price
        self.value = value
        self.side = side
        self.type = type
        self.id = id
    }
    
    static func limitSell(symbol: CryptoSymbol, qty: Decimal, price: Decimal, id: String) -> TradeOrderRequest {
        return TradeOrderRequest(symbol: symbol,
                               quantity: qty,
                               price: price,
                               side: .sell,
                               type: .limit,
                               id: id)
    }
    
    static func limitBuy(symbol: CryptoSymbol, qty: Decimal, price: Decimal, id: String) -> TradeOrderRequest {
        return TradeOrderRequest(symbol: symbol,
                               quantity: qty,
                               price: price,
                               side: .buy,
                               type: .limit,
                               id: id)
    }
    
    static func marketBuy(symbol: CryptoSymbol, qty: Decimal, id: String) -> TradeOrderRequest {
        return TradeOrderRequest(symbol: symbol,
                               quantity: qty,
                               price: nil,
                               side: .buy,
                               type: .market,
                               id: id)
    }
    
    static func marketBuy(symbol: CryptoSymbol, value: Decimal, id: String) -> TradeOrderRequest {
        return TradeOrderRequest(symbol: symbol,
                               value: value,
                               side: .buy,
                               type: .market,
                               id: id)
    }
    
    static func marketSell(symbol: CryptoSymbol, qty: Decimal, id: String) -> TradeOrderRequest {
        return TradeOrderRequest(symbol: symbol,
                               quantity: qty,
                               price: nil,
                               side: .sell,
                               type: .market,
                               id: id)
    }
    
    static func stopLossSell(symbol: CryptoSymbol, qty: Decimal, price: Decimal, id: String) -> TradeOrderRequest {
        return TradeOrderRequest(symbol: symbol,
                               quantity: qty,
                               price: price,
                               side: .sell,
                               type: .stopLoss,
                               id: id)
    }
    
    static func stopLossBuy(symbol: CryptoSymbol, qty: Decimal, price: Decimal, id: String) -> TradeOrderRequest {
        return TradeOrderRequest(symbol: symbol,
                               quantity: qty,
                               price: price,
                               side: .buy,
                               type: .stopLoss,
                               id: id)
    }
    
    var description: String {
        return "TradeOrderRequest '\(id)': \(type) \(side) \(quantity?.description ?? "?") @ \(price ?? 0)"
    }
}
