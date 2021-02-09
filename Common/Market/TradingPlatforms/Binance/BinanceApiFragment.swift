import Foundation

public class BinanceApiFragment {
    
    public let symbol: MarketPair
    let config: BinanceApiConfiguration
    
    var binanceSymbol: String {
        return stringify(symbol: symbol)
    }
    
    init(symbol: MarketPair, config: BinanceApiConfiguration) {
        self.symbol = symbol
        self.config = config
    }
    
    func stringify(symbol: MarketPair) -> String {
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
