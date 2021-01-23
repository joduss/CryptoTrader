//
//  Kraken.swift
//  Trader2
//
//  Created by Jonathan Duss on 09.01.21.
//

import Foundation


public class Kraken: CryptoExchangePlatform, WebSocketDelegate {
    
    private(set) public var subscribedToTickerStream: Bool = false
    private(set) public var subscribedToAggregatedTradeStream: Bool = false
    private(set) public var subscribedToMarketDepthStream: Bool = false
    
    private let baseUrl = URL(string: "wss://ws.kraken.com")!
    public let webSocketHandler: WebSocketHandler
    
    private var socket: WebSocket {
        
        if webSocketHandler.socket == nil {
            webSocketHandler.createSocket()
        }
        
        return webSocketHandler.socket!
    }
    
    public var subscriber: CryptoExchangePlatformSubscriber?
    public let marketPair: MarketPair
    
    public init(marketPair: MarketPair) {
        self.marketPair = marketPair
        
        webSocketHandler = WebSocketHandler(url: baseUrl)
        webSocketHandler.websocketDelegate = self
        webSocketHandler.createSocket()
    }

    // MARK: - TradingPlatform
    
    public func subscribeToTickerStream() {
        self.subscribedToTickerStream = true
        
        socket.send(message: """
            {
              "event": "subscribe",
              "pair": [
                "XBT/USD"
              ],
              "subscription": {
                "name": "ticker"
              }
            }
            """)
    }
    
    public func subscribeToAggregatedTradeStream() { }
    
    public func subscribeToMarketDepthStream() {}

    
    // MARK: - WebSocketDelegate
    
    public func process(response: String) {
        if response.starts(with: "[") {
            let serverResponse = KrakenTickerResponse(response: response)
            subscriber?.process(trade: MarketAggregatedTrade(date: Date(), symbol: marketPair.rawValue, price: serverResponse.price, quantity: 0, buyerIsMaker: false))
        }
    }
}
