import Foundation

struct BinanceSymbolConverter {
    
    static func convert(symbol: String) throws -> MarketPair {
        switch(symbol) {
        case "BTCUSDT":
            return .btc_usd
        case "ETHUSDT":
            return .eth_usd
        case "ICXUSDT":
            return .icx_usd
        default:
            throw TradingPlatformError.generalError(message: "Symbol \(symbol) is unknown")
        }
    }
    
    static func convert(symbol: MarketPair) -> String {
        switch symbol {
        case .btc_usd:
            return "BTCUSDT"
        case .eth_usd:
            return "ETHUSDT"
        case .icx_usd:
            return "ICXUSDT"
        }
    }
}
