import Foundation

public struct TraderGridStrategySavedState: Codable {
    
    let startDate: Date
    
    let initialBalance: Double
    let currentBalance: Double
    let profits: Double
    
    var orderGrid: [GridMarketPosition] = []
    var orderHistory: [GridTradeRecord] = []
}
