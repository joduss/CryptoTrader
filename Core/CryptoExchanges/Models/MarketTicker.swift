import Foundation

/// Information about a "ticker".
public struct MarketTicker: Codable {
    public var id: Int
    public var date: Date
    public var symbol: String
    public var bidPrice: Double
    public var bidQuantity: Double
    public var askPrice: Double
    public var askQuantity: Double
}
