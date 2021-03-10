import Foundation


struct TraderBTSStrategyConfigBTC: TraderBTSStrategyConfig {
    
    // MARK: General
    
    var maxOrdersCount: Int = 10
    
    
    // MARK: Buy rules
    
    /// A stop-loss order is created with a price X% higher than the current price.
    var buyStopLossPercent: Percent = 0.25
    
    /// Update the stop-loss order if the price goes lower than X% below the current price
    var buyUpdateStopLossPercent: Percent = 0.01
    
    var minDistancePercentNegative: Percent = -0.15
    var minDistancePercentPositive: Percent = 0.3
    
    var nextBuyTargetPercent: Percent = 0.1
    var nextBuyTargetExpiration: TimeInterval = TimeInterval.fromMinutes(120)
    
    
    var lockStrictInterval: TimeInterval = TimeInterval.fromMinutes(30)
    var lockCheckTrendInterval: TimeInterval = TimeInterval.fromHours(12)
    var lockTrendThreshold: Percent = 0.7
    var lock2LossesInLast: TimeInterval = TimeInterval.fromHours(16)
    var unlockTrendThreshold: Percent = 0.3
    var unlockCheckTrendInterval: TimeInterval = TimeInterval.fromMinutes(12)
    
    
    // MARK: SELL rules
    
    var sellStopLossProfitPercent: Percent = 0.75
    var minSellStopLossProfitPercent: Percent = 1
    
    var sellUpdateStopLossProfitPercent: Percent = 0.01
    
    var sellMinProfitPercent: Percent = 0.35
}
