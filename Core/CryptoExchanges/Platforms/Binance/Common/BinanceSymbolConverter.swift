import Foundation

struct BinanceSymbolConverter {
    
    static func convert(_ symbol: String) throws -> CryptoSymbol {
        switch(symbol) {
        case "BTCUSDT":
            return .btc_usd
        case "ETHUSDT":
            return .eth_usd
        case "ICXUSDT":
            return .icx_usd
        default:
            throw ExchangePlatformError.generalError(message: "Symbol \(symbol) is unknown")
        }
    }
    
    static func convert(_ symbol: CryptoSymbol) -> String {
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
