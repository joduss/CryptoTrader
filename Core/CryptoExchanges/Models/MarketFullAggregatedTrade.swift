import Foundation

public struct MarketFullAggregatedTrade: Codable {
    public let id: Int
    public let date: Date
    public let symbol: String
    public let price: Double
    public let quantity: Double
}
