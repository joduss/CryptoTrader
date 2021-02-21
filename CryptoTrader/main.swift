import Foundation
import ArgumentParser
import Cocoa
import os
import JoLibrary
import IkigaJSON

let arguments = CommandLine.arguments


struct TraderMain: ParsableCommand {
    
    // MARK: Command line options, arguments, etc
    // ------------------------------

    enum Action: EnumerableFlag {
        case trade, simulate
    }
    
    @Flag(exclusivity: .chooseFirst, help: "The market pair.")
    var marketPair: CryptoSymbol = .btc_usd
    
    @Flag(exclusivity: .chooseFirst, help: "What to do")
    var action: Action = .simulate
    
    @Argument(help: "Recorded tickers file.")
    var recordedTickersFile: String?
    
    @Argument(help: "Keep every N tickers.")
    var keepEvery: String?
    
    
    // MARK: Command line main.
    // ------------------------------
    func run() throws {
        sourcePrint("CryptoTrader started")
        
        switch action {
        case .trade:
            TraderMain.exit(withError: ValidationError("Trading is not yet supported"))
            break
        case .simulate:
            
            guard let recordedTickersFile = recordedTickersFile else {
                TraderMain.exit(withError: ValidationError("A path to the file containing data for simulation is required!"))
            }
            
            print("Running trader with simulation api.")
            
            DispatchQueue(label: "simulation").async { () in
                do {
                    try self.simulate(recordedTickersFile: recordedTickersFile)
                    print("DONE")
                }
                catch {
                    sourcePrint("SIMULATION FAILED")
                }
            }
            
            DispatchQueue.init(label: "User Input").async {
                var input = ""
                while(input != "x") {
                    input = readLine() ?? ""
   
                    if input == "x" {
                        TraderMain.exit()
                    }
                }
            }
            break
        }
    }
    
    
    //====================================================================
    // MARK: - Simulation
    //====================================================================
    
    
    /// Start the simulation
    func simulate(recordedTickersFile: String) throws {
        let reader = TextFileReader.openFile(at: recordedTickersFile)
        var idx = 0
        let keepEveryNTicker = Int(keepEvery ?? "5") ?? 5
        
        let jsonDecoder = JSONDecoder()
        var tickers = [MarketTicker]()
        tickers.reserveCapacity(30000000)
        
        while true {
            guard let line = reader.readLine() else {
                break
            }
            
            idx += 1

            if idx > 100000000 { break }
            if (idx % keepEveryNTicker != 0) { continue }

            let data = line.data(using: .utf8)!
            let ticker = try jsonDecoder.decode(MarketTicker.self, from: data)
            tickers.append(ticker)
        }
        
        let simulatedExchange = SimulatedFullExchange(symbol: .btc_usd, tickers: tickers)
        let trader = SimpleTrader(client: simulatedExchange, initialBalance: 300, currentBalance: 300, maxOrderCount: 12)
        
        simulatedExchange.start()
        (trader.strategy as? SimpleTraderBTSStrategy)?.summary()
    }
}

TraderMain.main()
RunLoop.main.run()


