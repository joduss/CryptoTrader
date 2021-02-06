//
//  Binance.swift
//  Trader2
//
//  Created by Jonathan Duss on 11.01.21.
//

import Foundation
import JoLibrary

final public class Binance: WebSocketDelegate, CryptoExchangePlatform {
    
    private let baseUrl = URL(string: "wss://stream.binance.com:9443/ws/a")!
    
    private var socket: WebSocket {
        return webSocketHandler.socket!
    }

    public let marketPair: MarketPair
    private var marketDepth = MarketDepth()
    
    private(set) public var subscribedToTickerStream: Bool = false
    private(set) public var subscribedToAggregatedTradeStream: Bool = false
    private(set) public var subscribedToMarketDepthStream: Bool = false
    
    public var webSocketHandler: WebSocketHandler
    public var subscriber: CryptoExchangePlatformSubscriber?
    
    
    public init(marketPair: MarketPair) {
        sourcePrint("Using Binance API")
        self.marketPair = marketPair
        
        webSocketHandler = WebSocketHandler(url: baseUrl)
        webSocketHandler.websocketDelegate = self
        webSocketHandler.createSocket()
    }
    
    public convenience init(marketPair: MarketPair, marketDepthBackup: MarketDepthBackup) {
        self.init(marketPair: marketPair)
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
                    "\(marketPairSymbol)@bookTicker"
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
                    "\(marketPairSymbol)@depth@1000ms"
                ],
                "id": 1
            }
            """)
    }

    
    // MARK: - Helpers
    
    private var marketPairSymbol: String {
        switch marketPair {
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
                    "\(marketPairSymbol)@aggTrade"
                ],
                "id": 1
            }
            """)
    }
        
    
    // MARK: - WebSocketDelegate
    
    public func process(response: String) {
        
        if response.starts(with: "{\"e\":\"aggTrade\",") {
            let binanceTrade = try! JSONDecoder().decode(BinanceAggregatedTradeResponse.self, from: response.data(using: .utf8)!)
            
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
            let binanceTicker = try! JSONDecoder().decode(BinanceTickerResponse.self, from: response.data(using: .utf8)!)
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
            
            let binanceDepth = try! JSONDecoder().decode(BinanceDepthUpdateResponse.self, from: response.data(using: .utf8)!)
            
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
