import Foundation

public struct MarketFullAggregatedTrade: Codable {
    public let id: Int
    public let date: Date
    public let symbol: String
    public let price: Decimal
    public let quantity: Decimal
}
