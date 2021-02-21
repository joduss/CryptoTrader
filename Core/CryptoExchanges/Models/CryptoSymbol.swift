import Foundation
import ArgumentParser


public enum CryptoSymbol: String, EnumerableFlag, CustomStringConvertible {
    /// USD or USDT depending on the exchange
    case eth_usd
    
    /// USD or USDT depending on the exchange
    case btc_usd
    
    /// USD or USDT depending on the exchange
    case icx_usd
    
    public var description: String {
        return self.rawValue
    }
}
