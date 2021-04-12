//

import Foundation

struct TraderMacdStrategyConfig {
    
    var maxOrdersCount: Int = 10

    var macdPeriod: Int = 5 // In minutes
    
    
    var macdShort: Int {
        return macdPeriod * 12
    }
    
    var macdLong: Int {
        return macdPeriod * 26
    }
    
    var macdSignal: Int {
        return macdPeriod * 9
    }
    
    var minDistancePercentBelow: Percent = -1
    var minDistancePercentAbove: Percent = 0.4
    
    var delayAfterOperation: TimeInterval = 600
    
    
    var minProfitsPercent: Percent = 0.25
    
//    var stopLoss
}
