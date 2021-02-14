import Foundation
import ArgumentParser


public enum CryptoSymbol: String, EnumerableFlag {
    /// USD or USDT depending on the exchange
    case eth_usd
    
    /// USD or USDT depending on the exchange
    case btc_usd
    
    /// USD or USDT depending on the exchange
    case icx_usd
}
