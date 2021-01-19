//
//  TradingPlatform.swift
//  Trader2
//
//  Created by Jonathan Duss on 09.01.21.
//

import Foundation

public protocol TradingPlatformDelegate: class {
    func priceUpdated(newPrice: Double)
}

public protocol TradingPlatform: class {
    var delegate: TradingPlatformDelegate? { get set }
    func listenBtcUsdPrice()
}
