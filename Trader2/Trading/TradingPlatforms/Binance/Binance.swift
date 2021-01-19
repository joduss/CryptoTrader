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
            
            // Response:
            //{"e":"depthUpdate","E":1610915374389,"s":"BTCUSDT","U":7964687236,"u":7964687413,"b":[["35628.90000000","0.00000000"],["35628.15000000","0.04305300"],["35627.93000000","0.06102300"],["35627.92000000","0.25581800"],["35627.79000000","0.00000000"],["35627.78000000","0.00000000"],["35616.97000000","0.00000000"],["35616.25000000","0.12945900"],["35614.82000000","0.00000000"],["35611.43000000","0.20000000"],["35604.45000000","0.30000000"],["35600.76000000","0.00303000"],["35585.29000000","0.05858600"],["35548.37000000","0.00000000"],["35529.87000000","0.00050000"],["33847.46000000","0.00084000"]],"a":[["35626.07000000","0.00000000"],["35626.92000000","0.00000000"],["35627.01000000","0.00000000"],["35627.38000000","0.00000000"],["35627.39000000","0.00000000"],["35627.93000000","0.00000000"],["35682.68000000","0.00000000"],["35685.07000000","1.00000000"],["35687.97000000","0.19300000"],["35700.00000000","4.72383900"],["35722.26000000","0.00050000"],["37407.36000000","0.00000000"]]}
            //{"e":"aggTrade","E":1610915374458,"s":"BTCUSDT","a":520089915,"p":"35628.53000000","q":"0.00349900","f":579028363,"l":579028363,"T":1610915374457,"m":false,"M":true}
            
    }
    
    // MARK: - WebSocketDelegate
    
    public func process(response: String) {
        
        if response.starts(with: "{\"e\":\"depthUpdate\"") {
            let serverResponse = KrakenTickerResponse(response: response)
            delegate?.priceUpdated(newPrice: serverResponse.price ?? 0)
            return
        }
        
        if response.starts(with: "{\"e\":\"depthUpdate\"") {
            
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
