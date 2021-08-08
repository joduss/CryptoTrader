import Foundation

struct TraderBTSSavedState: Codable {
    var openSellOperations: [TraderBTSSellOperation]
    var closedSellOperations: [TraderBTSSellOperation]
    var currentBalance: Double
    var initialBalance: Double
    var profits: Double
    var startDate: Date
}
