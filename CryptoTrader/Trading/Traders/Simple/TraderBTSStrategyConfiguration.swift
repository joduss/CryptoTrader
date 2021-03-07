import Foundation


struct TraderBTSStrategyConfiguration {
    
    var maxOrdersCount: Int = 10
    
    
    // Buying

    /// A stop-loss order is created with a price X% higher than the current price.
    var buyStopLossPercent: Percent = 0.5 // 0.8
    
    /// Update the stop-loss order if the price goes lower than X% below the current price
    var buyUpdateStopLossPercent: Percent = 0.01
        
    var minDistancePercentNegative: Percent = -0.5 // 1.3 //(lower increases the revenue)
    var minDistancePercentPositive: Percent = 0.5 // 0.5
    
    var nextBuyTargetPercent: Percent = 0.25 // negative
    var nextBuyTargetExpiration: TimeInterval = TimeInterval.fromMinutes(60)
    
    
    var lockStrictInterval: TimeInterval = 10.0 * 60.0
    var lockCheckTrendInterval: TimeInterval = 6 * 60 * 60.0
    var lockTrendThreshold: Percent = -0.2
    var lock2LossesInLast: TimeInterval = TimeInterval.fromHours(24)
    var unlockTrendThreshold: Percent = 0.1
    var unlockCheckTrendInterval: TimeInterval = 2 * 60 * 60.0
    
    // Selling

    /// The price increase(in % compared to current one) at which a stop-loss is created to
    /// take the profits if the price goes down again.
    var sellStopLossProfitPercent: Percent = 1 // 0.8 (avec 0.2 => 14.31)
    var minSellStopLossProfitPercent: Percent = 1

    /// Price increase (in % of the existing current price) at which the stop-loss profit
    /// price is updated.
    var sellUpdateStopLossProfitPercent: Percent = 0.01
    
    /// Minimum lower limit compared to initial price at which we sell.
    var sellMinProfitPercent: Percent = 0.35
}
