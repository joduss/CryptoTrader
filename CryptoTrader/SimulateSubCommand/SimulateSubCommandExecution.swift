import Foundation


class SimulateSubCommandExecution {
    
    let symbol: CryptoSymbol
    var initialBalance: Decimal
    var tickers: ContiguousArray<MarketTicker> = ContiguousArray<MarketTicker>()
    var trades: ContiguousArray<MarketMinimalAggregatedTrade> = ContiguousArray<MarketMinimalAggregatedTrade>()

    let dateFactory = DateFactory()
    
    internal init(symbol: CryptoSymbol,
                  initialBalance: Decimal,
                  tickersLocation: String?,
                  tradesLocation: String?,
                  dataStartIdx: Int? = nil,
                  dataEndIdx: Int? = nil) throws {
        self.symbol = symbol
        self.initialBalance = initialBalance
        
        let startIdx = dataStartIdx ?? 0
        let endIdx = dataEndIdx ?? Int.max
        
        if let tickersLocation = tickersLocation {
            self.tickers = MarketTickerDeserializer.loadTickers(from: tickersLocation, startIdx: startIdx, endIdx: endIdx)
        }
        
        if let tradesLocation = tradesLocation {
            self.trades = MarketMinimalAggregatedTradeDeserializer.loadTrades(from: tradesLocation, startIdx: startIdx, endIdx: endIdx)
        }
        
        printDateFactory = dateFactory
    }
    
    @discardableResult
    /// Returns (profits, summary)
    func execute(strategy: TradingStrategy) -> (Decimal, String){
        switch strategy {
            case .bts:
                return executeBTS(printPrice: true)
            case .macd:
                return executeMacd(printPrice: true)
        }
    }
    
    /// Returns (profits, summary)
    func executeMacd(printPrice: Bool = true, config: TraderMacdStrategyConfig? = nil) -> (Decimal, String) {
        let config = config ?? TraderMacdStrategyConfig()
        
        let simulation = TradingSimulation(symbol: symbol,
                                           simulatedExchange: createSimulatedExchange(),
                                           dateFactory: dateFactory,
                                           initialBalance: initialBalance)
        
        return simulation.simulate(config: config)
    }
    
    /// Returns (profits, summary)
    func executeBTS(printPrice: Bool = true, config: TraderBTSStrategyConfig? = nil) -> (Decimal, String) {
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
