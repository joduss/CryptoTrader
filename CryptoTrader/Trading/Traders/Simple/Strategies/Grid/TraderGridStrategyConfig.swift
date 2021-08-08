import Foundation

class TraderGridStrategyConfig {
    
    public var orderCount = 30
     
    public var gridSizePercent: Percent = 3
    public var gridSizeScenarioPriceDropPercent: Percent = 2
    public var scenarioPriceDropThresholdPercent: Percent = -4

    public var profitMinPercent: Percent = 2.5
    
    public var profitStopLossPercent: Percent = 0.4


    public var buyStopLossPercent: Percent = 0.5

    
    //public var stopLossPercent: Percent = -0.5
}
