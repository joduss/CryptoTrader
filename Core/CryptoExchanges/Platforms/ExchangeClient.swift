import Foundation


protocol ExchangeClient {
    
    var marketStream : ExchangeMarketDataStream { get }
    var userDataStream : ExchangeUserDataStream { get }
    var trading : ExchangeSpotTrading { get }
}
