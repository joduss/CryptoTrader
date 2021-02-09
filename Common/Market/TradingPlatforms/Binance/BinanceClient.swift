import Foundation

class BinanceClient {
    
    public let symbol: MarketPair
    private let config: BinanceApiConfiguration
    
    init(symbol: MarketPair, config: BinanceApiConfiguration) {
        self.symbol = symbol
        self.config = config
    }
    
    lazy private(set) var marketStream : BinanceMarketStream = {
        return BinanceMarketStream(symbol: symbol, config: config)
    }()
}
