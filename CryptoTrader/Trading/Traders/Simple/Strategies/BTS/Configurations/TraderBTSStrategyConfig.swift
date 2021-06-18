import Foundation


protocol TraderBTSStrategyConfig {
    
    // MARK: General
    
    var maxOrdersCount: Int { get set }
    
    
    // MARK: BUY rules
    
    /// A stop-loss order is created with a price X% higher than the current price.
    var buyStopLossPercent: Percent { get set }
    
    /// Update the stop-loss order if the price goes lower than X% below the current price
    var buyUpdateStopLossPercent: Percent { get set }
    
    var minDistancePercentNegative: Percent { get set }
    var minDistancePercentPositive: Percent { get set }
    
    /// Consider a dip when the price goes below in less than X minutes
    var dipDropThresholdPercent: Percent { get set }
    
    /// If the price dive by dipBelowPercent
    var dipDropThresholdTime: TimeInterval { get set }

    
    var lockStrictInterval: TimeInterval { get set }
    var lockCheckTrendInterval: TimeInterval { get set }
    var lockTrendThreshold: Percent { get set }
    var lock2LossesInLast: TimeInterval { get set }
    var unlockTrendThreshold: Percent { get set }
    var unlockCheckTrendInterval: TimeInterval { get set }
    
    // MARK: SELL rules
    
    /// The price increase(in % compared to current one) at which a stop-loss is created to
    /// take the profits if the price goes down again.
    var sellStopLossProfitPercent: Percent { get set }
    var minSellStopLossProfitPercent: Percent { get set }
    
    /// Price increase (in % of the existing current price) at which the stop-loss profit
    /// price is updated.
    var sellUpdateStopLossProfitPercent: Percent { get set }
    
    /// Minimum lower limit compared to initial price at which we sell.
    var sellMinProfitPercent: Percent { get set }
    
    
    // MARK: stop loss
    
    var stopLossPercent: Percent { get set }
}
