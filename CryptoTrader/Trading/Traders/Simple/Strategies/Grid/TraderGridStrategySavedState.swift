import Foundation

public struct TraderGridStrategySavedState: Codable {
    
    let startDate: Date
    
    let initialBalance: Decimal
    let currentBalance: Decimal
    let profits: Decimal
    
    var orderGrid: [GridMarketPosition] = []
    var orderHistory: [GridTradeRecord] = []
}
