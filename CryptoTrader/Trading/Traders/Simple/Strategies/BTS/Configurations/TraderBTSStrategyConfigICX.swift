import Foundation


struct TraderBTSStrategyConfigICX: TraderBTSStrategyConfig {
    
    // MARK: General
    
    var maxOrdersCount: Int = 10
    
    
    // MARK: Buy rules
    
    var buyStopLossPercent: Percent = 0.25
    
    var buyUpdateStopLossPercent: Percent = 0.01
    
    var minDistancePercentNegative: Percent = 1
    var minDistancePercentPositive: Percent = 1
    
    var nextBuyTargetPercent: Percent = 0.1
    var nextBuyTargetExpiration: TimeInterval = TimeInterval.fromMinutes(120)
    
    /// Consider a dip when the price goes below in less than X minutes
    var dipDropThresholdPercent: Percent = 3
    
    /// If the price dive by dipBelowPercent
    var dipDropThresholdTime: TimeInterval = TimeInterval.fromMinutes(10)
    
    
    var lockStrictInterval: TimeInterval = TimeInterval.fromMinutes(10)
    var lockCheckTrendInterval: TimeInterval = TimeInterval.fromHours(6)
    var lockTrendThreshold: Percent = 0.7
    var lock2LossesInLast: TimeInterval = TimeInterval.fromHours(4)
    var unlockTrendThreshold: Percent = 0.3
    var unlockCheckTrendInterval: TimeInterval = TimeInterval.fromMinutes(12)
    
    
    // MARK: SELL rules
    
    var sellStopLossProfitPercent: Percent = 0.75
    var minSellStopLossProfitPercent: Percent = 0.75
    
    /// Price increase (in % of the existing current price) at which the stop-loss profit
    /// price is updated.
    var sellUpdateStopLossProfitPercent: Percent = 0.01
    
    var sellMinProfitPercent: Percent = 0.35
    
    
    // MARK: SELL rules
    
    var stopLossPercent: Percent = -1000
}
