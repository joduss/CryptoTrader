import Foundation

public struct MarketAggregatedTrade: Codable {
    public let date: Date
    public let symbol: String
    public let price: Double
    public let quantity: Double
    public let buyerIsMaker: Bool
}
