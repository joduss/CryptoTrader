//

import Foundation

struct TraderMacdStrategyConfig {
    
    var maxOrdersCount: Int = 5

    var macdPeriod: Int = 25 // In minutes
    
    // Number of periods for short
    var macdShort: Int {
        return 8
    }
    
    // Number of periods for long
    var macdLong: Int {
        return 17
    }
    
    // Number of periods for signal
    var macdSignal: Int {
        return 9
    }
    
    /// Min distance between the order above and a new order
    var minDistancePercentBelow: Percent? = -0.75
    
    /// Min distance between the order below and a new order
    var minDistancePercentAbove: Percent? = 1.0
    
    
    
    var minProfitsPercent: Percent = 0.8
    var stopLossPercent: Percent = -1000
}
