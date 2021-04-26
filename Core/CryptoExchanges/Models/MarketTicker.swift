import Foundation

/// Information about a "ticker".
public struct MarketTicker: Codable {
    public var id: Int
    public var date: Date
    public var symbol: String
    public var bidPrice: Decimal
    public var bidQuantity: Decimal
    public var askPrice: Decimal
    public var askQuantity: Decimal
}
