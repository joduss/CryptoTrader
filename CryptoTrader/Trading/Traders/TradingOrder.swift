//
//  TradingOrder.swift
//  Trader2
//
//  Created by Jonathan Duss on 19.01.21.
//

import Foundation

class TradingOrder {
    
    let date: Date
    private(set) var originalPrice: Double
    private(set) var originalAmount: Double
    private(set) var originalCost: Double

    private(set) var sellPrice: Double?
    
    
    init(price: Double, amount: Double, cost: Double) {
        date = DateFactory.now
        originalPrice = price
        originalAmount = amount
        originalCost = cost
    }
    
    func closeOrderSelling(at price: Double) {
        sellPrice = price
    }
    
    func sell(at price: Double) {
        
    }
}
