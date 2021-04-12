import Foundation


class SimulateSubCommandExecution {
    
    let symbol: CryptoSymbol
    var initialBalance: Double
    let maxOrderCount: Int
    var tickers: ContiguousArray<MarketTicker> = ContiguousArray<MarketTicker>()
    
    let dateFactory = DateFactory()
    
    internal init(symbol: CryptoSymbol,
                  initialBalance: Double,
                  maxOperationCount: Int,
                  tickersLocation: String,
                  tickersStartIdx: Int? = nil,
                  tickersEndIdx: Int? = nil) throws {
        self.symbol = symbol
        self.initialBalance = initialBalance
        self.maxOrderCount = maxOperationCount
        
        let startIdx = tickersStartIdx ?? 0
        let endIdx = tickersEndIdx ?? Int.max
        
        self.tickers = MarketTickerDeserializer.loadTickers(from: tickersLocation, startIdx: startIdx, endIdx: endIdx)
        printDateFactory = dateFactory
    }
    
    @discardableResult
    /// Returns (profits, summary)
    func execute(strategy: TradingStrategy) -> (Double, String){
        switch strategy {
            case .bts:
                return executeBTS(printPrice: true)
            case .macd:
                return executeMacd(printPrice: true)
        }
    }
    
    /// Returns (profits, summary)
    func executeMacd(printPrice: Bool = true, config: TraderMacdStrategyConfig? = nil) -> (Double, String) {
        var config = config ?? TraderMacdStrategyConfig()
        config.maxOrdersCount = maxOrderCount
        
        let simulation = TradingSimulation(symbol: symbol,
                                           simulatedExchange: createSimulatedExchange(),
                                           dateFactory: dateFactory,
                                           initialBalance: initialBalance)
        
        return simulation.simulate(config: config, printPrice: printPrice)
    }
    
    /// Returns (profits, summary)
    func executeBTS(printPrice: Bool = true, config: TraderBTSStrategyConfig? = nil) -> (Double, String){
        var config: TraderBTSStrategyConfig!  = config
        
        if config == nil {
            switch symbol {
                case .btc_usd:
                    config = TraderBTSStrategyConfigBTC()
                    break
                case .eth_usd:
                    config = TraderBTSStrategyConfigETH()
                case .icx_usd:
                    config = TraderBTSStrategyConfigICX()
            }
        }
        
        config.maxOrdersCount = maxOrderCount
        
        let simulation = TradingSimulation(symbol: symbol,
                                           simulatedExchange: createSimulatedExchange(),
                                           dateFactory: dateFactory,
                                           initialBalance: initialBalance)
                
        return simulation.simulate(config: config, printPrice: printPrice)
    }
    
    private func createSimulatedExchange() -> SimulatedFullExchange {
        return SimulatedFullExchange(symbol: symbol, tickers: tickers, dateFactory: dateFactory)
    }
}
