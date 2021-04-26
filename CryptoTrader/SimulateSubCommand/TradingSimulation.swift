import Foundation


class TradingSimulation {
    
    let symbol: CryptoSymbol
    let simulatedExchange: SimulatedFullExchange
    let dateFactory: DateFactory
    let initialBalance: Decimal
    
    var shouldPrint = true
    
    
    init(symbol: CryptoSymbol, simulatedExchange: SimulatedFullExchange, dateFactory: DateFactory, initialBalance: Decimal) {
        self.symbol = symbol
        self.simulatedExchange = simulatedExchange
        self.dateFactory = dateFactory
        self.initialBalance = initialBalance
    }
    
    func simulate(config: TraderBTSStrategyConfig) -> (Decimal, String) {
        
        let strategy = TraderBTSStrategy(exchange: simulatedExchange,
                                               config: config,
                                               initialBalance: initialBalance,
                                               currentBalance: initialBalance,
                                               saveStateLocation: FileManager.default.temporaryDirectory.absoluteString,
                                               dateFactory: dateFactory)
        strategy.saveEnabled = false
        _ = SimpleTrader(client: simulatedExchange, strategy: strategy)
        
        simulatedExchange.start()
        
        let description =
            """
            CONFIG: \(config)

            \(strategy.summary(shouldPrint: shouldPrint))
            """
        
        return (strategy.profits, description)
    }
    
    func simulate(config: TraderMacdStrategyConfig) -> (Decimal, String) {
        let strategy = TraderMACDStrategy(exchange: simulatedExchange,
                                                   config: config,
                                                   initialBalance: initialBalance,
                                                   currentBalance: initialBalance,
                                                   saveStateLocation: FileManager.default.temporaryDirectory.absoluteString,
                                                   dateFactory: dateFactory)
        strategy.saveEnabled = false
        _ = SimpleTrader(client: simulatedExchange, strategy: strategy)
        
        simulatedExchange.start()
        
        let description =
            """
            CONFIG: \(config)

            \(strategy.summary())
            """
        
        return (strategy.profits, description)
    }
    
}
