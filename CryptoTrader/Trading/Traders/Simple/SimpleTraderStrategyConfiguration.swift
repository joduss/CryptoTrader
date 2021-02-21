import Foundation


struct SimpleTraderStrategyConfiguration {
    
    var maxOrdersCount: Int = 12
    
    
    // Buying

    /// A stop-loss order is created with a price X% higher than the current price.
    let buyStopLossPercent: Percent = 0.5
    
    /// Update the stop-loss order if the price goes lower than X% below the stop-loss order price
    let buyUpdateStopLossPercent: Percent = 0.7
    
    /// If the price goes up and up, then we might place another order to buy even more even thought we didn't
    /// sell yet what we previously bought.
    let buyNextBuyOrderPercent = 1.0
    
    // Selling

    /// The price (in % compared to current one) at which a stop-loss is created to
    /// take the profits.
    let sellStopLossProfitPercent: Percent = 0.7
    
    /// Price (in % of the existing stop-loss profit) at which the stop-loss profit
    /// price is updated.
    let updateSellUpperLimitPercent: Percent = 0.9
    

    
    let sellLowerLimitDivisor = 4.0
    

    
    /// Minimum lower limit compared to initial price at which we sell.
    let sellMinProfitPercent: Percent = 0.25
    
    let minDistancePercentNegative: Percent = -1.0
    let minDistancePercentPositive: Percent = 0.7

    

}
