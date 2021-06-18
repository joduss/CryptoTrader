import Foundation


class SimulateSubCommandExecution {
    
    let symbol: CryptoSymbol
    var initialBalance: Decimal
    var tickers: ContiguousArray<MarketTicker> = ContiguousArray<MarketTicker>()
    var trades: ContiguousArray<MarketMinimalAggregatedTrade> = ContiguousArray<MarketMinimalAggregatedTrade>()

    let dateFactory = DateFactory()
    
    internal init(symbol: CryptoSymbol,
                  initialBalance: Decimal,
                  dataLocation: String,
                  dataStartIdx: Int? = nil,
                  dataEndIdx: Int? = nil,
                  keepEvery: Int = 1) throws {
        self.symbol = symbol
        self.initialBalance = initialBalance
        
        let startIdx = dataStartIdx ?? 0
        let endIdx = dataEndIdx ?? Int.max
        
        if (dataLocation.contains(".tickers")) {
            self.tickers = MarketTickerDeserializer.loadTickers(from: dataLocation,
                                                                startIdx: startIdx,
                                                                endIdx: endIdx)
        }
        else {
            self.tickers = MarketMinimalAggregatedTradeDeserializer.loadTradesAsTickers(from: dataLocation,
                                                                                        startIdx: startIdx,
                                                                                        endIdx: endIdx,
                                                                                        keepEvery: keepEvery,
                                                                                        symbol: symbol)
        }
        
        printDateFactory = dateFactory
    }
    
    @discardableResult
    /// Returns (profits, summary)
    func execute(strategy: TradingStrategy) -> TradingSimulationResults {
        switch strategy {
            case .bts:
                return executeBTS(printPrice: true)
            case .macd:
                return executeMacd(printPrice: true)
        }
    }
    
    /// Returns (profits, summary)
    func executeMacd(printPrice: Bool = true, config: TraderMacdStrategyConfig? = nil) -> TradingSimulationResults {
        let config = config ?? TraderMacdStrategyConfig()
        
        let simulation = TradingSimulation(symbol: symbol,
                                           simulatedExchange: createSimulatedExchange(),
                                           dateFactory: dateFactory,
                                           initialBalance: initialBalance)
        
        return simulation.simulate(config: config)
    }
    
    /// Returns (profits, summary)
    func executeBTS(printPrice: Bool = true, config: TraderBTSStrategyConfig? = nil) -> TradingSimulationResults {
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
        
        
        let simulation = TradingSimulation(symbol: symbol,
                                           simulatedExchange: createSimulatedExchange(),
                                           dateFactory: dateFactory,
                                           initialBalance: initialBalance)
                
        return simulation.simulate(config: config)
    }
    
    private func createSimulatedExchange() -> SimulatedExchange {
        if tickers.count == 0 {
            return SimulatedTradeBasedExchange(symbol: symbol, trades: trades, dateFactory: dateFactory)
        }
        else {
            return SimulatedTickerBasedExchange(symbol: symbol, tickers: tickers, dateFactory: dateFactory)
        }
    }
}
