import Foundation


struct SimpleTraderStrategyConfiguration {
    
    var maxOrdersCount: Int = 12
    
    ///The initial limit set at which the limits will be updated
    let initialUpperLimitPercent = 1.0
    
    let sellLowerLimitDivisor = 4.0
    
    /// How much does it need to grow so that we update the lower limit at which we should sell due to decrease of price
    let updateSellUpperLimitPercent: Percent = 0.35
    
    /// How much lower can be the price at which we sell to take the profits in case the price goes down again.
    let maxSellLowerLimitPercent: Percent = 0.7
    
    /// Minimum lower limit compared to initial price at which we sell.
    let minLowerLimitPercent: Percent = 0.25
    
    let minDistancePercentNegative: Percent = -1.0
    let minDistancePercentPositive: Percent = 0.7

    
    let prepareBuyOverPricePercent: Percent = 0.5
    let updatePrepareBuyOverPricePercent: Percent = 0.5
}
