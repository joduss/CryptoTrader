//
//  Kraken.swift
//  Trader2
//
//  Created by Jonathan Duss on 09.01.21.
//

import Foundation


public class Kraken: WebSocketDelegate, TradingPlatform {
    
    let url = "wss://ws.kraken.com"
    var socket: WebSocket
    
    public var delegate: TradingPlatformDelegate?
    
    public init() {
        socket = WebSocket(url: URL(string: url)!)
        socket.delegate = self
        socket.connect()
    }
    
    private func createSocket() {
        socket = WebSocket(url: URL(string: url)!)
        socket.delegate = self
        socket.connect()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: {
            self.listenBtcUsdPrice()
        })
    }

    public func listenBtcUsdPrice() {
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
    
    // MARK: - WebSocketDelegate
    
    public func process(response: String) {
        if response.starts(with: "[") {
            let serverResponse = KrakenTickerResponse(response: response)
            delegate?.priceUpdated(newPrice: serverResponse.price ?? 0)
        }
    }
    
    public func error() {
        sourcePrint("Websocket connection did encounter an error...")
        socket.delegate = nil
        socket.disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [self] in
            createSocket()
        }
    }
    
    public func didClose() {
        sourcePrint("Websocket connection did close...")
        socket.delegate = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [self] in
            createSocket()
        }
    }
}
