import Foundation

public class BinanceApiFragment {
    
    public let symbol: CryptoSymbol
    let config: BinanceApiConfiguration
    
    var binanceSymbol: String {
        return stringify(symbol: symbol)
    }
    
    init(symbol: CryptoSymbol, config: BinanceApiConfiguration) {
        self.symbol = symbol
        self.config = config
    }
    
    func stringify(symbol: CryptoSymbol) -> String {
        switch symbol {
            case .btc_usd:
                return "btcusdt"
            case .eth_usd:
                return "ethusdt"
            case .icx_usd:
                return "icxusdt"
        }
    }
}
