import Foundation

class BinanceClient {
    
    public let symbol: MarketPair
    private let config: BinanceApiConfiguration
    private let requestSender: BinanceApiRequestSender
    
    init(symbol: MarketPair, config: BinanceApiConfiguration) {
        self.symbol = symbol
        self.config = config
        requestSender = BinanceApiRequestSender(config: config)
    }
    
    lazy private(set) var marketStream : BinanceMarketStream = {
        return BinanceMarketStream(symbol: symbol, config: config)
    }()
    
    lazy private(set) var userDataStream : BinanceUserDataStream = {
        return BinanceUserDataStream(symbol: symbol, config: config)
    }()
    
    lazy private(set) var trading : BinanceTrading = {
        return BinanceTrading(symbol: symbol, config: config)
    }()
}
