import Foundation


struct TradingApiOrderRequest {
    let qty: Double
    let price: Double
    let symbol: CryptoSymbol
    let customId: String
}
