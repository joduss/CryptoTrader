import Foundation


struct Order: Codable {
    var date: Date
    var price: Double
    var qty: Double
}

struct Variability {
    var min: Double
    var max: Double
    var average: Double
    
    var spikes07Percent: UInt
    var spikes1Percent: UInt
    
    var variabilityRatioToPrice: Double {
        return (max - min) / average
    }
}





// IDEE

// Vendre quand plus bas, puis racheter si threshold 0.99 atteint ou 102.
// Pareil achat


final class SimpleTrader: CryptoExchangePlatformSubscriber {
    
    let marketAnalyzer = MarketPerSecondHistory(intervalToKeep: TimeInterval.fromHours(2.01))
    var api : CryptoExchangePlatform
    
    var orderSize: Double = 200
    var balance: Double = 250.0
    
    var orders: [TradingOrder] = []
    
    var closedOrder: TradingOrder?
    
    var fees = Percent(0.1)
    
    var profits: Double = 0
    
    var canBuy: Bool {
        return balance > orderSize &&
            (orders.count == 0 || !orders.contains(where: {order in return DateFactory.now - order.date < TimeInterval.fromMinutes(5)}))
    }
    
    let fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("prices2.json")
    var filePath: String {
        return fileUrl.absoluteURL.path
    }
    
    private var market5MinCache: MarketHistorySlice?
    private var market10Cache: MarketHistorySlice?
    private var market2HourCache: MarketHistorySlice?
    private var market30Cache: MarketHistorySlice?
    
    private var market10Min:  MarketHistorySlice {
        if market10Cache == nil {
            market10Cache = marketAnalyzer.prices(last: TimeInterval.fromMinutes(10))!
        }
        return market10Cache!
    }
    
    private var market5Min: MarketHistorySlice {
        if market5MinCache == nil {
            market5MinCache = market10Min.prices(last: TimeInterval.fromMinutes(5))
        }
        return market5MinCache!
    }
    
    private var market2Hour: MarketHistorySlice {
        if market2HourCache == nil {
            market2HourCache = marketAnalyzer.prices(last: TimeInterval.fromHours(2))
        }
        return market2HourCache!
    }
    
    private var market30Min:  MarketHistorySlice {
        if market30Cache == nil {
            market30Cache = marketAnalyzer.prices(last: TimeInterval.fromMinutes(30))!
        }
        return market30Cache!
    }
    
    
    init(api: CryptoExchangePlatform) {
        self.api = api
        self.api.subscriber = self
        api.subscribeToAggregatedTradeStream()
    }
    
    private func resetCurrentMarketStats() {
        market10Cache = nil
        market2HourCache = nil
        market30Cache = nil
    }
    
    func process(ticker: MarketTicker) {

    }
    
    func process(trade: MarketAggregatedTrade) {
        marketAnalyzer.record(trade)
        
        resetCurrentMarketStats()
        
        decide(price: trade.price)
    }
    
    func process(depthUpdate: MarketDepth) {
        
    }
    
    private var decisionCount = 0
    
    func decide(price: Double) {
        decisionCount += 1
        
        if decisionCount % 100 == 0 {
            sourcePrint("Decision for price \(price)")
        }
        
//        let dispatchGroup = DispatchGroup()
//
//        DispatchQueue(label: "1").async {
//            dispatchGroup.enter()
//            self.market2Hour.slope()
//            dispatchGroup.leave()
//        }
//
//        DispatchQueue(label: "2").async {
//            dispatchGroup.enter()
//            self.market30Min.slope()
//            dispatchGroup.leave()
//        }
//
//        DispatchQueue(label: "3").async {
//            dispatchGroup.enter()
//            self.market5Min.slope()
//            dispatchGroup.leave()
//        }
//
//
//        dispatchGroup.wait()
        
        
        if canBuy && marketAnalyzer.hasRecordFromAtLeastPastInterval(TimeInterval.fromHours(2)) {
            decideNewBuy(price: price)
        }
        
        for order in orders {
            
            if order.canBuy {
                decideRebuy(order: order, price: price)
            }
            else if (order.canSell) {
                decideSell(order: order, price: price)
            }
        }
    }
    
//    func decideNewBuy(price: Double) {
//
//        if price > market2Hour.maxPrice() { return }
//
//        if price > market2Hour.average() && market2Hour.maxPrice() / price > fromPercent(2) {
//            // buy
//            buy(price: price)
//            return
//        }
//
//        if price < market2Hour.average() && market30Min.slope() > 1 {
//            // buy
//            buy(price: price)
//            return
//        }
//    }
    
    func fromPercent(_ value: Double) -> Double {
        return value / 100.0
    }
    
    func toPercent(_ value: Double) -> Double {
        return value * 100
    }
    
//    func decideSell(order: TradingOrder, price: Double) {
//
//        // Selling can occur in 2 cases:
//        // - Price is high, and we do profits
//        // - Price is low and we want to sell it, let it go lower to buy it later to maximize profit when the high price is back
//
//        // Case 1: Price is high
//        if order.initialPrice < price {
//
//            // We set a limit sell earlier and now the price got lower again. Time to sell
//
//            if let closePrice = order.lowLimit, closePrice > price {
//                sourcePrint("Selling now: high price was not holding up.")
//                let cost = price * order.quantity -% Percent(0.1)
//                order.closeOrderSelling(at: price, forCost: cost)
//                return
//            }
//
//            // The price is high. Let's set a stop loss.
//            if order.lowLimit == nil && price >= order.initialPrice * fromPercent(101.2) {
//                sourcePrint("Price is high. Let's put a stop loss order.")
//                order.lowLimit = order.initialPrice * fromPercent(100.8)
//                return
//            }
//
//            // The price went even higher. Let's update the stop loss!
//            let newStopLoss = price * fromPercent(99)
//            if let currentSellStopLoss = order.lowLimit, newStopLoss > currentSellStopLoss {
//                order.lowLimit = newStopLoss
//            }
//
//            return
//        }
//
//        // Ho no, the price go lower...
//
//        // Let's still try to take advantage from the price going down!
//        let slope = Percent(-0.1 / 30 / 60) // -0.1 over 30 min
//
//        if toPercent(price / order.initialPrice) < 99
//            && Percent(ratioOf: market30Min.slope(), to: market30Min.average()) < slope
//            && Percent(ratioOf: market10Min.slope(), to: market10Min.average()) < slope
//            && Percent(ratioOf: market5Min.slope(), to: market5Min.average()) < slope {
//            sourcePrint("Price is lower, but let sell and buy it at a even lower price.")
//            intermediateSell(order: order, at: price)
//            return
//        }
//    }
//
//
//    func decideRebuy(order: TradingOrder, price: Double) {
//
//        // Rebuying can occur in cases:
//        // - The price reached the bottom and starts to raise again
//        // - Bad luck, we sold and to avoid too much losses we need to buy it back at a high price...
//
//        let priceToIntermediatePrice = (price / order.price).asPercent
//
//        // In this case, we couldn't rebuy at a lower price...
//        if priceToIntermediatePrice > Percent(103) && market30Min.slope() > 0.05 || priceToIntermediatePrice > Percent(104) {
//            // rebuy at a loss
//            rebuy(order: order, at: price)
//        }
//
//        // Price is low!
//        if priceToIntermediatePrice < Percent(98.8) {
//
//            // We set a limit at which we'll sell
//
//            let limitBuy = price * Percent(100.3)
//
//            // The price started to climb again. Let's buy.
//            if let currentLimitBuy = order.upperLimit, currentLimitBuy < price {
//                // Test if would resell at the point. If yes => don't sell, but update the order
//                rebuy(order: order, at: price)
//                return
//            }
//
//            // The price got even lower, let's update the limit at which we'll rebuy
//            if let currentLimitBuy = order.upperLimit, currentLimitBuy > limitBuy {
//                order.upperLimit = limitBuy
//                return
//            }
//
//            // The price decreased and we can now have profits for sure (almost)
//            // Let's define the limit at which we'll buy back if the price start to raise again.
//            if order.upperLimit == nil {
//                order.upperLimit = limitBuy
//                return
//            }
//        }
//    }
//
//
//    func buy(price: Double) {
//
//        balance -= orderSize
//
//        let qty = (orderSize / price) -% fees
//        let order = TradingOrder(price: price, amount: qty, cost: qty * price)
//        self.orders.append(order)
//
//        sourcePrint("At \(DateFactory.now) Bought \(qty) for \(price)")
//    }

    func closeSell(order: TradingOrder, at price: Double) {

        let sellCost = (order.quantity * price) -% fees
        let sellProfits = sellCost - order.initialValue
        order.closeOrderSelling(at: price, forCost: sellCost)
        profits += sellProfits
        balance += sellCost
        self.orders.removeAll(where: {$0 === order})
        
        closedOrder = order

        sourcePrint("[Trade] Selling order made the \(order.date) (\(order.initialQty) @ \(order.initialPrice)). Selling \(order.quantity) @ \(price) for a cost of \(sellCost). Profits of \(sellProfits). Total profits: \(profits).")
    }

    func rebuy(order: TradingOrder, at price: Double) {
        order.intermediateBuy(quantityBought: (order.value / price) -% fees, at: price)
    }

    func intermediateSell(order: TradingOrder, at price: Double) {
        order.intermediateSell(at: price, for: (price * order.quantity) -% fees)
    }
    
    
    
    // Technic 2
    
    func decideNewBuy(price: Double) {
        let market1Hour = market2Hour.prices(last: TimeInterval.fromHours(1))
        
        if price > market1Hour.maxPrice() { return }
        
        
        if let lastOrder = closedOrder {
            
            if abs(Percent(differenceOf: price, from: lastOrder.price).percentage) > 1 {
                // continue
            }
            else if lastOrder.closeDate! - DateFactory.now < 300 {
                return
            }
        }
        
        
        if price > market1Hour.average() && market2Hour.maxPrice() / price > fromPercent(2) {
            // buy
            buy(price: price)
            return
        }
        
        if price < market1Hour.average() && market10Min.slope() > 0 {
            buy(price: price)
            return
        }
    }
    
    func decideRebuy(order: TradingOrder, price: Double) {
        if price > order.upperLimit {
            rebuy(order: order, at: price)
            
            order.upperLimit = order.initialPrice +% Percent(1)
            order.lowLimit = price -% Percent(3)
            return
        }
        
        if price < order.lowLimit {
            // Need a new low limit and upper limit at which it will be rebough!
            order.upperLimit = price +% Percent(0.4)
            order.lowLimit = price -% Percent(0.15)
            return
        }
    }

    func decideSell(order: TradingOrder, price: Double) {
        
        if price > order.initialPrice {
            
            // If the price is higher than the upper limit, we update the limits
            if price > order.upperLimit {
                order.upperLimit = price +% Percent(0.1)
                order.lowLimit = price -% Percent(0.35)
                return
            }
            
            // If the price goes below the lower limit, but is higher than the original price, we close
            if price < order.lowLimit {
                closeSell(order: order, at: price)
            }
            
            return
        }
        
        // The price is lower than the initial price.
        // If it goes too low, we sell and will rebuy hopefully at a even lower price.
        if price < order.lowLimit {
            intermediateSell(order: order, at: price)
            
            order.upperLimit = price +% Percent(3)
            order.lowLimit = price -% Percent(1)
            return
        }
    }

    func buy(price: Double) {

        balance -= orderSize

        let qty = (orderSize / price) -% fees
        let order = TradingOrder(price: price, amount: qty, cost: orderSize)
        self.orders.append(order)
        
        order.upperLimit = price +% Percent(1)
        order.lowLimit = price -% Percent(1)

        sourcePrint("[Trade] At \(DateFactory.now) Bought \(qty) for \(price). Cost: \(orderSize)")
    }

    func summary() {
        let currentPrice = marketAnalyzer.prices(last: TimeInterval.fromMinutes(1))
        let coins: Double = orders.reduce(0.0, {result, newItem in return result + (newItem.currentQty ?? 0.0)})
        
        sourcePrint("Summary: Current balance = \(balance), coins = \(coins) at price \(currentPrice!)")
    }
}



//import Foundation
//
//
//struct Order: Codable {
//    var date: Date
//    var price: Double
//    var qty: Double
//}
//
//struct Variability {
//    var min: Double
//    var max: Double
//    var average: Double
//
//    var spikes07Percent: UInt
//    var spikes1Percent: UInt
//
//    var variabilityRatioToPrice: Double {
//        return (max - min) / average
//    }
//}
//
//
//
//
//
//// IDEE
//
//// Vendre quand plus bas, puis racheter si threshold 0.99 atteint ou 102.
//// Pareil achat
//
//
//final class SimpleTrader: CryptoExchangePlatformSubscriber {
//
//    let marketAnalyzer = MarketPerSecondHistory(intervalToKeep: TimeInterval.fromHours(2.01))
//    var api : CryptoExchangePlatform
//
//    var orderSize: Double = 200
//    var balance: Double = 250.0
//
//    var orders: [TradingOrder] = []
//
//    var closedOrder: TradingOrder?
//
//    var fees = Percent(0.1)
//
//    var profits: Double = 0
//
//    var canBuy: Bool {
//        return balance > orderSize &&
//            (orders.count == 0 || !orders.contains(where: {order in return DateFactory.now - order.date < TimeInterval.fromMinutes(5)}))
//    }
//
//    let fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("prices2.json")
//    var filePath: String {
//        return fileUrl.absoluteURL.path
//    }
//
//    private var market5MinCache: MarketHistorySlice?
//    private var market10Cache: MarketHistorySlice?
//    private var market2HourCache: MarketHistorySlice?
//    private var market30Cache: MarketHistorySlice?
//
//    private var market10Min:  MarketHistorySlice {
//        if market10Cache == nil {
//            market10Cache = marketAnalyzer.prices(last: TimeInterval.fromMinutes(10))!
//        }
//        return market10Cache!
//    }
//
//    private var market5Min: MarketHistorySlice {
//        if market5MinCache == nil {
//            market5MinCache = market10Min.prices(last: TimeInterval.fromMinutes(5))
//        }
//        return market5MinCache!
//    }
//
//    private var market2Hour: MarketHistorySlice {
//        if market2HourCache == nil {
//            market2HourCache = marketAnalyzer.prices(last: TimeInterval.fromHours(2))
//        }
//        return market2HourCache!
//    }
//
//    private var market30Min:  MarketHistorySlice {
//        if market30Cache == nil {
//            market30Cache = marketAnalyzer.prices(last: TimeInterval.fromMinutes(30))!
//        }
//        return market30Cache!
//    }
//
//
//    init(api: CryptoExchangePlatform) {
//        self.api = api
//        self.api.subscriber = self
//        api.subscribeToAggregatedTradeStream()
//    }
//
//    private func resetCurrentMarketStats() {
//        market10Cache = nil
//        market2HourCache = nil
//        market30Cache = nil
//    }
//
//    func process(ticker: MarketTicker) {
//
//    }
//
//    func process(trade: MarketAggregatedTrade) {
//        marketAnalyzer.record(trade)
//
//        resetCurrentMarketStats()
//
//        decide(price: trade.price)
//    }
//
//    func process(depthUpdate: MarketDepth) {
//
//    }
//
//    private var decisionCount = 0
//
//    func decide(price: Double) {
//        decisionCount += 1
//
//        if decisionCount % 100 == 0 {
//            sourcePrint("Decision for price \(price)")
//        }
//
////        let dispatchGroup = DispatchGroup()
////
////        DispatchQueue(label: "1").async {
////            dispatchGroup.enter()
////            self.market2Hour.slope()
////            dispatchGroup.leave()
////        }
////
////        DispatchQueue(label: "2").async {
////            dispatchGroup.enter()
////            self.market30Min.slope()
////            dispatchGroup.leave()
////        }
////
////        DispatchQueue(label: "3").async {
////            dispatchGroup.enter()
////            self.market5Min.slope()
////            dispatchGroup.leave()
////        }
////
////
////        dispatchGroup.wait()
//
//
//        if canBuy && marketAnalyzer.hasRecordFromAtLeastPastInterval(TimeInterval.fromHours(2)) {
//            decideNewBuy(price: price)
//        }
//
//        for order in orders {
//
//            if order.canBuy {
//                decideRebuy(order: order, price: price)
//            }
//            else if (order.canSell) {
//                decideSell(order: order, price: price)
//            }
//        }
//    }
//
////    func decideNewBuy(price: Double) {
////
////        if price > market2Hour.maxPrice() { return }
////
////        if price > market2Hour.average() && market2Hour.maxPrice() / price > fromPercent(2) {
////            // buy
////            buy(price: price)
////            return
////        }
////
////        if price < market2Hour.average() && market30Min.slope() > 1 {
////            // buy
////            buy(price: price)
////            return
////        }
////    }
//
//    func fromPercent(_ value: Double) -> Double {
//        return value / 100.0
//    }
//
//    func toPercent(_ value: Double) -> Double {
//        return value * 100
//    }
//
////    func decideSell(order: TradingOrder, price: Double) {
////
////        // Selling can occur in 2 cases:
////        // - Price is high, and we do profits
////        // - Price is low and we want to sell it, let it go lower to buy it later to maximize profit when the high price is back
////
////        // Case 1: Price is high
////        if order.initialPrice < price {
////
////            // We set a limit sell earlier and now the price got lower again. Time to sell
////
////            if let closePrice = order.lowLimit, closePrice > price {
////                sourcePrint("Selling now: high price was not holding up.")
////                let cost = price * order.quantity -% Percent(0.1)
////                order.closeOrderSelling(at: price, forCost: cost)
////                return
////            }
////
////            // The price is high. Let's set a stop loss.
////            if order.lowLimit == nil && price >= order.initialPrice * fromPercent(101.2) {
////                sourcePrint("Price is high. Let's put a stop loss order.")
////                order.lowLimit = order.initialPrice * fromPercent(100.8)
////                return
////            }
////
////            // The price went even higher. Let's update the stop loss!
////            let newStopLoss = price * fromPercent(99)
////            if let currentSellStopLoss = order.lowLimit, newStopLoss > currentSellStopLoss {
////                order.lowLimit = newStopLoss
////            }
////
////            return
////        }
////
////        // Ho no, the price go lower...
////
////        // Let's still try to take advantage from the price going down!
////        let slope = Percent(-0.1 / 30 / 60) // -0.1 over 30 min
////
////        if toPercent(price / order.initialPrice) < 99
////            && Percent(ratioOf: market30Min.slope(), to: market30Min.average()) < slope
////            && Percent(ratioOf: market10Min.slope(), to: market10Min.average()) < slope
////            && Percent(ratioOf: market5Min.slope(), to: market5Min.average()) < slope {
////            sourcePrint("Price is lower, but let sell and buy it at a even lower price.")
////            intermediateSell(order: order, at: price)
////            return
////        }
////    }
////
////
////    func decideRebuy(order: TradingOrder, price: Double) {
////
////        // Rebuying can occur in cases:
////        // - The price reached the bottom and starts to raise again
////        // - Bad luck, we sold and to avoid too much losses we need to buy it back at a high price...
////
////        let priceToIntermediatePrice = (price / order.price).asPercent
////
////        // In this case, we couldn't rebuy at a lower price...
////        if priceToIntermediatePrice > Percent(103) && market30Min.slope() > 0.05 || priceToIntermediatePrice > Percent(104) {
////            // rebuy at a loss
////            rebuy(order: order, at: price)
////        }
////
////        // Price is low!
////        if priceToIntermediatePrice < Percent(98.8) {
////
////            // We set a limit at which we'll sell
////
////            let limitBuy = price * Percent(100.3)
////
////            // The price started to climb again. Let's buy.
////            if let currentLimitBuy = order.upperLimit, currentLimitBuy < price {
////                // Test if would resell at the point. If yes => don't sell, but update the order
////                rebuy(order: order, at: price)
////                return
////            }
////
////            // The price got even lower, let's update the limit at which we'll rebuy
////            if let currentLimitBuy = order.upperLimit, currentLimitBuy > limitBuy {
////                order.upperLimit = limitBuy
////                return
////            }
////
////            // The price decreased and we can now have profits for sure (almost)
////            // Let's define the limit at which we'll buy back if the price start to raise again.
////            if order.upperLimit == nil {
////                order.upperLimit = limitBuy
////                return
////            }
////        }
////    }
////
////
////    func buy(price: Double) {
////
////        balance -= orderSize
////
////        let qty = (orderSize / price) -% fees
////        let order = TradingOrder(price: price, amount: qty, cost: qty * price)
////        self.orders.append(order)
////
////        sourcePrint("At \(DateFactory.now) Bought \(qty) for \(price)")
////    }
//
//    func closeSell(order: TradingOrder, at price: Double) {
//
//        let sellCost = (order.quantity * price) -% fees
//        let sellProfits = sellCost - order.initialValue
//        order.closeOrderSelling(at: price, forCost: sellCost)
//        profits += sellProfits
//        balance += sellCost
//        self.orders.removeAll(where: {$0 === order})
//
//        closedOrder = order
//
//        sourcePrint("[Trade] Selling order made the \(order.date) (\(order.initialQty) @ \(order.initialPrice)). Selling \(order.quantity) @ \(price) for a cost of \(sellCost). Profits of \(sellProfits). Total profits: \(profits).")
//    }
//
//    func rebuy(order: TradingOrder, at price: Double) {
//        order.intermediateBuy(quantityBought: (order.value / price) -% fees, at: price)
//    }
//
//    func intermediateSell(order: TradingOrder, at price: Double) {
//        order.intermediateSell(at: price, for: (price * order.quantity) -% fees)
//    }
//
//
//
//    // Technic 2
//
//    func decideNewBuy(price: Double) {
//        let market1Hour = market2Hour.prices(last: TimeInterval.fromHours(1))
//
//        if price > market1Hour.maxPrice() { return }
//
//
//        if let lastOrder = closedOrder {
//
//            if abs(Percent(differenceOf: price, from: lastOrder.price).percentage) > 1 {
//                // continue
//            }
//            else if lastOrder.closeDate! - DateFactory.now < 300 {
//                return
//            }
//        }
//
//
//        if price > market1Hour.average() && market2Hour.maxPrice() / price > fromPercent(2) {
//            // buy
//            buy(price: price)
//            return
//        }
//
//        if price < market1Hour.average() && market10Min.slope() > 0 {
//            buy(price: price)
//            return
//        }
//    }
//
//    func decideRebuy(order: TradingOrder, price: Double) {
//        if price > order.upperLimit {
//            rebuy(order: order, at: price)
//
//            order.upperLimit = order.initialPrice +% Percent(1)
//            order.lowLimit = price -% Percent(0.5)
//            return
//        }
//
//        if price < order.lowLimit {
//            // Need a new low limit and upper limit at which it will be rebough!
//            order.upperLimit = price +% Percent(0.35)
//            order.lowLimit = price -% Percent(0.15)
//            return
//        }
//    }
//
//    func decideSell(order: TradingOrder, price: Double) {
//
//        if price > order.initialPrice {
//
//            // If the price is higher than the upper limit, we update the limits
//            if price > order.upperLimit {
//                order.upperLimit = price +% Percent(0.1)
//                order.lowLimit = price -% Percent(0.35)
//                return
//            }
//
//            // If the price goes below the lower limit, but is higher than the original price, we close
//            if price < order.lowLimit {
//                closeSell(order: order, at: price)
//            }
//
//            return
//        }
//
//        // The price is lower than the initial price.
//        // If it goes too low, we sell and will rebuy hopefully at a even lower price.
//        if price < order.lowLimit {
//            intermediateSell(order: order, at: price)
//
//            order.upperLimit = price +% Percent(3)
//            order.lowLimit = price -% Percent(1)
//            return
//        }
//    }
//
//    func buy(price: Double) {
//
//        balance -= orderSize
//
//        let qty = (orderSize / price) -% fees
//        let order = TradingOrder(price: price, amount: qty, cost: orderSize)
//        self.orders.append(order)
//
//        order.upperLimit = price +% Percent(1)
//        order.lowLimit = price -% Percent(1)
//
//        sourcePrint("[Trade] At \(DateFactory.now) Bought \(qty) for \(price). Cost: \(orderSize)")
//    }
//
//    func summary() {
//        let currentPrice = marketAnalyzer.prices(last: TimeInterval.fromMinutes(1))
//        let coins: Double = orders.reduce(0.0, {result, newItem in return result + (newItem.currentQty ?? 0.0)})
//
//        sourcePrint("Summary: Current balance = \(balance), coins = \(coins) at price \(currentPrice!)")
//    }
//}
