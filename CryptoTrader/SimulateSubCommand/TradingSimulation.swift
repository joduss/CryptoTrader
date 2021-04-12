import Foundation


class TradingSimulation {
    
    let symbol: CryptoSymbol
    let simulatedExchange: SimulatedFullExchange
    let dateFactory: DateFactory
    let initialBalance: Double
    
    
    init(symbol: CryptoSymbol, simulatedExchange: SimulatedFullExchange, dateFactory: DateFactory, initialBalance: Double) {
        self.symbol = symbol
        self.simulatedExchange = simulatedExchange
        self.dateFactory = dateFactory
        self.initialBalance = initialBalance
    }
    
    func simulate(config: TraderBTSStrategyConfig, printPrice: Bool = false) -> (Double, String) {
        
        let strategy = SimpleTraderBTSStrategy(exchange: simulatedExchange,
                                               config: config,
                                               initialBalance: initialBalance,
                                               currentBalance: initialBalance,
                                               saveStateLocation: FileManager.default.temporaryDirectory.absoluteString,
                                               dateFactory: dateFactory)
        strategy.saveEnabled = false
        let trader = SimpleTrader(client: simulatedExchange, strategy: strategy)
        trader.printCurrentPrice = printPrice
        
        simulatedExchange.start()
        
        let description =
            """
            CONFIG: \(config)

            \(strategy.summary(shouldPrint: printPrice))
            """
        
        return (strategy.profits, description)
    }
    
    func simulate(config: TraderMacdStrategyConfig, printPrice: Bool = false) -> (Double, String) {
        let strategy = TraderMACDStrategy(exchange: simulatedExchange,
                                                   config: config,
                                                   initialBalance: initialBalance,
                                                   currentBalance: initialBalance,
                                                   saveStateLocation: FileManager.default.temporaryDirectory.absoluteString,
                                                   dateFactory: dateFactory)
        strategy.saveEnabled = false
        let trader = SimpleTrader(client: simulatedExchange, strategy: strategy)
        trader.printCurrentPrice = printPrice
        
        simulatedExchange.start()
        
        let description =
            """
            CONFIG: \(config)

            \(strategy.summary(shouldPrint: printPrice))
            """
        
        return (strategy.profits, description)
    }
    
}
