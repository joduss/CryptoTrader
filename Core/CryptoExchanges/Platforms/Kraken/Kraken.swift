//
//  Kraken.swift
//  Trader2
//
//  Created by Jonathan Duss on 09.01.21.
//

import Foundation


public class Kraken: MarketDataStream, WebSocketDelegate {
    
    public let symbol: CryptoSymbol

    public private(set) var subscribedToTickerStream: Bool = false
    public private(set) var subscribedToAggregatedTradeStream: Bool = false
    public private(set) var subscribedToMarketDepthStream: Bool = false
    public private(set) var subscribedtoUserOrderUpdateStream: Bool = false

    private let baseUrl = URL(string: "wss://ws.kraken.com")!
    public let webSocketHandler: WebSocketHandler
    
    private var socket: WebSocket {
        
        if webSocketHandler.socket == nil {
            webSocketHandler.createSocket()
        }
        
        return webSocketHandler.socket!
    }
    
    public var subscriber: MarketDataStreamSubscriber?
    
    public init(symbol: CryptoSymbol) {
        self.symbol = symbol
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
    
    public func subscribeToAggregatedTradeStream() {}
    
    public func subscribeToMarketDepthStream() {}

    public func subscribeToUserDataStream() {}
    
    // MARK: - WebSocketDelegate
    
    public func process(response: String) {
        if response.starts(with: "[") {
            let serverResponse = KrakenTickerResponse(response: response)
            subscriber?.process(trade: MarketAggregatedTrade(id: Int.random(in: 0...Int.max),date: Date(), symbol: symbol.rawValue, price: serverResponse.price, quantity: 0, buyerIsMaker: false))
        }
    }
}
