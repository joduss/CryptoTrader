//
//  Binance.swift
//  Trader2
//
//  Created by Jonathan Duss on 11.01.21.
//

import Foundation

public class Binance: WebSocketDelegate, TradingPlatform {
    
    let baseUrl = URL(string: "wss://stream.binance.com:9443")!

    var liveDataSocket: WebSocket?
    
    public var delegate: TradingPlatformDelegate?
    
    public init() {
        
    }

    public func listenBtcUsdPrice() {
        liveDataSocket = WebSocket(url: baseUrl.appendingPathComponent("ws").appendingPathComponent("a"))
        liveDataSocket?.delegate = self
        liveDataSocket?.connect()
        
        liveDataSocket?.send(message: """
            {
                "method": "SUBSCRIBE",
                "params":
                    [
                    "btcusdt@aggTrade",
                    "btcusdt@depth"
                ],
                "id": 1
            }
            """)
    }
    
    // MARK: - WebSocketDelegate
    
    public func process(response: String) {
        if response.starts(with: "[") {
            let serverResponse = Response(response: response)
            delegate?.priceUpdated(newPrice: serverResponse.price ?? 0)
        }
    }
    
    public func error() {
        liveDataSocket?.delegate = nil
        liveDataSocket?.disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [self] in
            listenBtcUsdPrice()
        }
    }
    
    public func didClose() {
        liveDataSocket?.delegate = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [self] in
            listenBtcUsdPrice()
        }
    }
}
