import Foundation

/// Information about a "ticker".
public struct MarketTicker: Codable {
    public let id: Int
    public let date: Date
    public let symbol: String
    public let bidPrice: Double
    public let bidQuantity: Double
    public let askPrice: Double
    public let askQuantity: Double
}
