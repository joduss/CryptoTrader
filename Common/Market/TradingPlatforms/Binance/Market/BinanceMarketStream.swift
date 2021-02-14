import Foundation
import JoLibrary

final public class BinanceMarketStream: BinanceApiFragment, WebSocketDelegate, MarketDataStream {

    private let baseUrl = URL(string: "wss://stream.binance.com:9443/ws/a")!

    private var marketDepth = MarketDepth()

    private var socket: WebSocket {
        return webSocketHandler.socket!
    }

    public private(set) var subscribedToTickerStream: Bool = false
    public private(set) var subscribedToAggregatedTradeStream: Bool = false
    public private(set) var subscribedToMarketDepthStream: Bool = false
    public private(set) var subscribedtoUserOrderUpdateStream = false
    
    public var webSocketHandler: WebSocketHandler
    
    public var subscriber: MarketDataStreamSubscriber?
    
    
    public override init(symbol: MarketPair, config: BinanceApiConfiguration) {
        sourcePrint("Using Binance API")
                
        webSocketHandler = WebSocketHandler(url: baseUrl)
        super.init(symbol: symbol, config: config)

        webSocketHandler.websocketDelegate = self
        webSocketHandler.createSocket()
    }
    
    public convenience init(symbol: MarketPair, config: BinanceApiConfiguration, marketDepthBackup: MarketDepthBackup) {
        self.init(symbol: symbol, config: config)
        self.marketDepth = MarketDepth(marketDepthBackup: marketDepthBackup)

        sourcePrint("Initialized Binance with depth backup...")
        sourcePrint("Loaded \(marketDepth.bids.count) bids and \(marketDepth.asks.count) asks")
    }

    
    // MARK: - TradingPlatform

    public func subscribeToTickerStream() {
        self.subscribedToTickerStream = true
        socket.send(message: """
            {
                "method": "SUBSCRIBE",
                "params":
                    [
                    "\(binanceSymbol)@bookTicker"
                ],
                "id": 1
            }
            """)
    }
    
    public func subscribeToAggregatedTradeStream() {
        self.subscribedToAggregatedTradeStream = true
        self.internalSubscribeToAggregatedTradeStream()
    }
    
    public func subscribeToMarketDepthStream() {
        self.subscribedToMarketDepthStream = true
        self.internalSubscribeToAggregatedTradeStream()

        socket.send(message: """
            {
                "method": "SUBSCRIBE",
                "params":
                    [
                    "\(binanceSymbol)@depth@1000ms"
                ],
                "id": 1
            }
            """)
    }

    
    // MARK: - Helpers
    
    private func marketPairSymbol(_ symbol: MarketPair) -> String {
        switch symbol {
        case .btc_usd:
            return "btcusdt"
        case .eth_usd:
            return "ethusdt"
        case .icx_usd:
            return "icxusdt"
        }
    }
    
    private func internalSubscribeToAggregatedTradeStream() {
        socket.send(message: """
            {
                "method": "SUBSCRIBE",
                "params":
                    [
                    "\(binanceSymbol)@aggTrade"
                ],
                "id": 1
            }
            """)
    }
        
    
    // MARK: - WebSocketDelegate
    
    public func process(response: String) {
        do {
            try parse(response)
        } catch {
            sourcePrint("ERROR: Parsing the response resulted in an error: \(error)")
        }
    }
    
    private func parse(_ response: String) throws {
        if response.starts(with: "{\"e\":\"aggTrade\",") {
            let binanceTrade = try JSONDecoder().decode(BinanceAggregatedTradeResponse.self, from: response.data(using: .utf8)!)
            
            // Update the market depth.
            if abs(marketDepth.currentPrice - binanceTrade.price) > marketDepth.currentPrice / 100 {
                marketDepth.currentPrice = binanceTrade.price
            }
            
            marketDepth.currentPrice = binanceTrade.price
            
            guard self.subscribedToAggregatedTradeStream else { return }
            
            let trade = MarketAggregatedTrade(id: binanceTrade.tradeId,
                                              date: Date(),
                                              symbol: binanceTrade.symbol,
                                              price: binanceTrade.price,
                                              quantity: binanceTrade.quantity,
                                              buyerIsMaker: binanceTrade.buyerIsMarker)
            subscriber?.process(trade: trade)
            return
        }
        
        if response.starts(with: "{\"u\":") {
            let binanceTicker = try JSONDecoder().decode(BinanceTickerResponse.self, from: response.data(using: .utf8)!)
            let ticker = MarketTicker(id: binanceTicker.updateId,
                                      date: Date(),
                                      symbol: binanceTicker.symbol,
                                      bidPrice: binanceTicker.bidPrice,
                                      bidQuantity: binanceTicker.bidQuantity,
                                      askPrice: binanceTicker.askPrice,
                                      askQuantity: binanceTicker.askQuantity)
            subscriber?.process(ticker: ticker)
            return
        }
        
        if response.starts(with: "{\"e\":\"depthUpdate\"") {
            
            let binanceDepth = try JSONDecoder().decode(BinanceDepthUpdateResponse.self, from: response.data(using: .utf8)!)
            
            let askUpdates = binanceDepth.askUpdates.map({MarketDepthElement(priceLevel: $0.priceLevel, quantity: $0.quantity)})
            marketDepth.updateAsks(askUpdates)

            let bidUpdates = binanceDepth.bidUpdates.map({MarketDepthElement(priceLevel: $0.priceLevel, quantity: $0.quantity)})
            marketDepth.updateBids(bidUpdates)
            
            marketDepth.updateId(binanceDepth.eventTime)
                        
            subscriber?.process(depthUpdate: marketDepth)
            return
        }
    }
}
