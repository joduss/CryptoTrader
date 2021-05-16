import Foundation

public struct MarketAggregatedTrade: Codable {
    public let id: Int
    public let date: Date
    public let symbol: String
    public let buyerIsMaker: Bool
    public let price: Decimal
    public let quantity: Decimal
}
