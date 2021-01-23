import Foundation
import ArgumentParser


public enum MarketPair: String, EnumerableFlag {
    /// USD or USDT depending on the exchange
    case eth_usd
    
    /// USD or USDT depending on the exchange
    case btc_usd
}
