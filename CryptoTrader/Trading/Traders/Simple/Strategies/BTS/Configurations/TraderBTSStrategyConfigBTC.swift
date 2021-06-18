import Foundation

//for maxOrder in [18] { // 18
//    for buyStopLossPercent in [0.8] { // 0.8
//        for sellStopLossProfitPercent in [0.5] { // 0.5
//            for minDistancePercentNegative in [-0.2] { // -0.2
//                for minDistancePercentPositive in [0.4] { // 0.4
//                    for nextBuyTargetPercent in [50.0] { // 0.1
//                        for nextBuyTargetExpiration in [30.0] { // minutes // 30 0
//                            for lockTrendThreshold in [0.0] { // 0
//                                for unlockTrendThreshold in [0.0] { // 0
//                                    for lock2LossesInLast in [16.0] { // 12 hours
//                                        for unlockCheckTrendInterval in [6.0] { // 6 (very clear)
//                                            for lockCheckTrendInterval in [1.0] { // 1 (very clear)
//                                                for lockStrictInterval in [180.0] {// minutes // 180
//                                                    for dipDropThresholdPercent in [1.5] { // 1.5
//                                                        for dipDropThresholdTime in [45] { // 45
//                                                            for sellMinProfitPercent in [0.9] { // 0.9
//                                                                for minSellStopLossProfitPercent in [sellStopLossProfitPercent] {
struct TraderBTSStrategyConfigBTC: TraderBTSStrategyConfig {
    
    // MARK: General
    
    var maxOrdersCount: Int = 18
    
    
    // MARK: Buy rules
    
    /// A stop-loss order is created with a price X% higher than the current price.
    var buyStopLossPercent: Percent = 0.8
    
    /// Update the stop-loss order if the price goes lower than X% below the current price
    var buyUpdateStopLossPercent: Percent = 0.01
    
    var minDistancePercentNegative: Percent = -0.2
    var minDistancePercentPositive: Percent = 0.4
    
    /// Consider a dip when the price goes below in less than X minutes
    var dipDropThresholdPercent: Percent = 1.5
    
    /// If the price dive by dipBelowPercent
    var dipDropThresholdTime: TimeInterval = TimeInterval.fromMinutes(45)
    
    var lockStrictInterval: TimeInterval = TimeInterval.fromMinutes(180)
    var lockCheckTrendInterval: TimeInterval = TimeInterval.fromHours(1.0)
    var lockTrendThreshold: Percent = 0.0
    var lock2LossesInLast: TimeInterval = TimeInterval.fromHours(16)
    var unlockTrendThreshold: Percent = 0
    var unlockCheckTrendInterval: TimeInterval = TimeInterval.fromHours(6)
    
    
    // MARK: SELL rules
    
    var sellStopLossProfitPercent: Percent = 0.5
    var minSellStopLossProfitPercent: Percent = 0.5
    
    var sellUpdateStopLossProfitPercent: Percent = 0.01
    
    /// Min profit allowed
    var sellMinProfitPercent: Percent = 0.9
    
    
    // MARK: SELL rules
    
    var stopLossPercent: Percent = -10000

}
