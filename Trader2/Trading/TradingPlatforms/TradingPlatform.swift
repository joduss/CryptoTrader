//
//  TradingPlatform.swift
//  Trader2
//
//  Created by Jonathan Duss on 09.01.21.
//

import Foundation

public protocol TradingPlatformSubscriber: class {
    func process(ticker: MarketTicker)
    func process(trade: MarketAggregatedTrade)
    func process(depthUpdate: MarketDepth)

}

public protocol TradingPlatform: class, WebSocketDelegate {
    var subscribedToTickerStream: Bool { get }
    var subscribedToAggregatedTradeStream: Bool { get }
    var subscribedToMarketDepthStream: Bool { get }

    var webSocketHandler: WebSocketHandler { get }
    var marketPair: MarketPair { get }
    var subscriber: TradingPlatformSubscriber? { get set }
    
    func subscribeToTickerStream()
    func subscribeToAggregatedTradeStream()
    func subscribeToMarketDepthStream()

}

extension TradingPlatform {
    
    func resubscribe() {
        if subscribedToTickerStream {
            self.subscribeToTickerStream()
        }
        
        if subscribedToAggregatedTradeStream {
            self.subscribeToAggregatedTradeStream()
        }
        
        if subscribedToMarketDepthStream {
            self.subscribeToMarketDepthStream()
        }
    }
    
    func recreateSocket() {
        webSocketHandler.createSocket { success in
            if success {
                self.resubscribe()
            }
            else {
                sourcePrint("Re-creating the socket failed... trying again in 10 seconds...")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: { [weak self] in
                    self?.recreateSocket()
                })
            }
        }
    }
    
    public func error() {
        sourcePrint("Websocket connection did encounter an error...")
        recreateSocket()
    }
    
    public func didClose() {
        sourcePrint("Websocket connection did close...")
        recreateSocket()
    }
}


