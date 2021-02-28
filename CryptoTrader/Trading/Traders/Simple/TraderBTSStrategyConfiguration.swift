import Foundation


struct TraderBTSStrategyConfiguration {
    
    var maxOrdersCount: Int = 9
    
    
    // Buying

    /// A stop-loss order is created with a price X% higher than the current price.
    let buyStopLossPercent: Percent = 0.5
    
    /// Update the stop-loss order if the price goes lower than X% below the current price
    let buyUpdateStopLossPercent: Percent = 0.7
        
    let minDistancePercentNegative: Percent = -1.3
    let minDistancePercentPositive: Percent = 0.71
    
    
    // Selling

    /// The price increase(in % compared to current one) at which a stop-loss is created to
    /// take the profits if the price goes down again.
    let sellStopLossProfitPercent: Percent = 0.7
    
    /// Price increase (in % of the existing current price) at which the stop-loss profit
    /// price is updated.
    let sellUpdateStopLossProfitPercent: Percent = 0.35
    
    // For very small profits.
//    let sellLowerLimitDivisor = 4.0
    
    /// Minimum lower limit compared to initial price at which we sell.
    let sellMinProfitPercent: Percent = 0.25
    
    

}
