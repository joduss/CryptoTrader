import Foundation


struct TraderBTSStrategyConfigETH: TraderBTSStrategyConfig {
    
    // MARK: General
    
    var maxOrdersCount: Int = 15
    
    
    // MARK: Buy rules
    
    /// A stop-loss order is created with a price X% higher than the current price.
    var buyStopLossPercent: Percent = 0.25
    
    /// Update the stop-loss order if the price goes lower than X% below the current price
    var buyUpdateStopLossPercent: Percent = 0.01
    
    var minDistancePercentNegative: Percent = -0.5
    var minDistancePercentPositive: Percent = 0.3
    
    var nextBuyTargetPercent: Percent = 0.05 // Negative
    var nextBuyTargetExpiration: TimeInterval = TimeInterval.fromMinutes(120)
    
    /// Consider a dip when the price goes below in less than X minutes
    var dipDropThresholdPercent: Percent = 3
    
    /// If the price dive by dipBelowPercent
    var dipDropThresholdTime: TimeInterval = TimeInterval.fromMinutes(15)
    
    var lockStrictInterval: TimeInterval = TimeInterval.fromMinutes(30)
    var lockCheckTrendInterval: TimeInterval = TimeInterval.fromHours(12)
    var lockTrendThreshold: Percent = 0.0
    var lock2LossesInLast: TimeInterval = TimeInterval.fromHours(1)
    var unlockTrendThreshold: Percent = 0.3
    var unlockCheckTrendInterval: TimeInterval = TimeInterval.fromHours(12)
    
    
    // MARK: SELL rules
    
    var sellStopLossProfitPercent: Percent = 0.6
    var minSellStopLossProfitPercent: Percent = 0.6
    
    var sellUpdateStopLossProfitPercent: Percent = 0.01
    
    var sellMinProfitPercent: Percent = 0.45
    
    
    
    // MARK: SELL rules
    
    var stopLossPercent: Percent = -10
}
