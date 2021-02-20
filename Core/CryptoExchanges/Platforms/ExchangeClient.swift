import Foundation


protocol ExchangeClient {
    
    var symbol: CryptoSymbol { get }
    
    var marketStream : ExchangeMarketDataStream { get }
    var userDataStream : ExchangeUserDataStream { get }
    var trading : ExchangeSpotTrading { get }
}
