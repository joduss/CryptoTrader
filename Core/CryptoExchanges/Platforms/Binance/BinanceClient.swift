import Foundation

class BinanceClient: ExchangeClient {
    
    public let symbol: CryptoSymbol
    private let config: BinanceApiConfiguration
    private let requestSender: BinanceApiRequestSender
    
    init(symbol: CryptoSymbol, config: BinanceApiConfiguration) {
        self.symbol = symbol
        self.config = config
        requestSender = BinanceApiRequestSender(config: config)
    }
    
    lazy private(set) var marketStream : ExchangeMarketDataStream = {
        return BinanceMarketStream(symbol: symbol, config: config)
    }()
    
    lazy private(set) var userDataStream : ExchangeUserDataStream = {
        return BinanceUserDataStream(symbol: symbol, config: config)
    }()
    
    lazy private(set) var trading : ExchangeSpotTrading = {
        return BinanceTrading(symbol: symbol, config: config)
    }()
}
