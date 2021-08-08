import Foundation

class TraderGridStrategyConfig {
    
    public var orderCount = 30
     
    public var gridSizePercent: Percent = 1
    public var profitMin: Percent = 1.25
    public var profitStopLoss: Percent = -0.25
    public var profitStopLossUpdate: Percent = 0.05
    
    public var stopLoss: Percent = -0.5
}
