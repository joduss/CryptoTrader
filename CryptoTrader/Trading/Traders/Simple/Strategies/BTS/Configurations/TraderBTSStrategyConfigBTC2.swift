import Foundation

// Profits 59.3639394307049 from bts-3
struct TraderBTSStrategyConfigBTC2: TraderBTSStrategyConfig {
    
    // MARK: General
    
    var maxOrdersCount: Int = 14
    
    
    // MARK: Buy rules
    
    /// A stop-loss order is created with a price X% higher than the current price.
    var buyStopLossPercent: Percent = 0.6
    
    /// Update the stop-loss order if the price goes lower than X% below the current price
    var buyUpdateStopLossPercent: Percent = 0.01
    
    var minDistancePercentNegative: Percent = -0.2
    var minDistancePercentPositive: Percent = 0.8
    
    /// Consider a dip when the price goes below in less than X minutes
    var dipDropThresholdPercent: Percent = 3.5
    
    /// If the price dive by dipBelowPercent
    var dipDropThresholdTime: TimeInterval = TimeInterval.fromMinutes(45)
    
    var lockStrictInterval: TimeInterval = TimeInterval.fromMinutes(180)
    var lockCheckTrendInterval: TimeInterval = TimeInterval.fromHours(1.0)
    var lockTrendThreshold: Percent = 0.0
    var lock2LossesInLast: TimeInterval = TimeInterval.fromHours(12)
    var unlockTrendThreshold: Percent = 0
    var unlockCheckTrendInterval: TimeInterval = TimeInterval.fromHours(6)
    
    
    // MARK: SELL rules
    
    var sellStopLossProfitPercent: Percent = 0.4
    var minSellStopLossProfitPercent: Percent = 0.4
    
    var sellUpdateStopLossProfitPercent: Percent = 0.01
    
    /// Min profit allowed
    var sellMinProfitPercent: Percent = 1.3
}
