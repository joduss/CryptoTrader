import Foundation

struct TraderMACDStrategySavedState: Codable {
    
    var openOperations: [MacdOperation]
    var closeOperations: [MacdOperation]
    var currentBalance: Decimal
    var initialBalance: Decimal
    var orderValue: Decimal
    var profits: Decimal
    var startDate: Date
}
