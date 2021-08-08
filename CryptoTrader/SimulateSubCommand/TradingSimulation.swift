import Foundation


struct TradingSimulationResults {
    let simulationLog: String
    let accumulatedProfits: Decimal
    let currentValue: Decimal
    let openOrderCount: Int
}

class TradingSimulation {
    
    let symbol: CryptoSymbol
    let simulatedExchange: SimulatedExchange
    let dateFactory: DateFactory
    let initialBalance: Decimal
    
    var shouldPrint = true
    
    
    init(symbol: CryptoSymbol, simulatedExchange: SimulatedExchange, dateFactory: DateFactory, initialBalance: Decimal) {
        self.symbol = symbol
        self.simulatedExchange = simulatedExchange
        self.dateFactory = dateFactory
        self.initialBalance = initialBalance
    }
    
    func simulate(config: TraderBTSStrategyConfig) -> TradingSimulationResults {
        
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
        
        return TradingSimulationResults(simulationLog: description,
                                        accumulatedProfits: strategy.profits,
                                        currentValue: strategy.balanceValue,
                                        openOrderCount: strategy.openOrders)
    }
    
    func simulate(config: TraderMacdStrategyConfig) -> TradingSimulationResults {
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
        
        return TradingSimulationResults(simulationLog: description,
                                        accumulatedProfits: strategy.profits,
                                        currentValue: strategy.balanceValue,
                                        openOrderCount: strategy.openOrders)
    }
    
    func simulate(config: TraderGridStrategyConfig) -> TradingSimulationResults {
        let strategy = TraderGridStrategy(exchange: simulatedExchange,
                                          config: config,
                                          initialBalance: initialBalance,
                                          saveStateLocation: FileManager.default.temporaryDirectory.absoluteString,
                                          dateFactory: self.dateFactory)
        strategy.saveEnabled = false
        _ = SimpleTrader(client: simulatedExchange, strategy: strategy)
        simulatedExchange.start()
        
        let log =
            """
            CONFIG: \(config)
            
            \(strategy.summary(shouldPrint: true))
            """
        return TradingSimulationResults(simulationLog: log,
                                        accumulatedProfits: strategy.profits,
                                        currentValue: strategy.balanceValue,
                                        openOrderCount: strategy.openOrders)
    }
    
}
