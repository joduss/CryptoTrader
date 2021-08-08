import Foundation
import ArgumentParser

enum TradingStrategy : String, EnumerableFlag {
    case macd = "macd"
    case bts = "bts"
    case gridtrader = "gridtrader"
}
