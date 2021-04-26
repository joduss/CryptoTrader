import Foundation

struct TraderBTSSavedState: Codable {
    var openSellOperations: [TraderBTSSellOperation]
    var closedSellOperations: [TraderBTSSellOperation]
    var currentBalance: Decimal
    var initialBalance: Decimal
    var profits: Decimal
    var startDate: Date
}
