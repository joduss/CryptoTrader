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


class SimpleTrader: TradingPlatformSubscriber {
    
    let marketAnalyzer = MarketHistory(intervalToKeep: TimeInterval.fromHours(1.05))
    var api : TradingPlatform
    
    var orderSize: Double = 69
    var balance: Double = 210.0
    var orders: [Order] = []
    
    var fees = 0.1 / 100
    
    var profits: Double = 0
    
    var canBuy: Bool {
        return balance > orderSize &&
            (orders.count == 0 || !orders.contains(where: {order in return DateFactory.now - order.date < TimeInterval.fromMinutes(5)}))
    }
    
    let fileUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("prices2.json")
    var filePath: String {
        return fileUrl.absoluteURL.path
    }
    
    init(api: TradingPlatform) {
        self.api = api
        api.subscribeToTickerStream()
        self.api.subscriber = self
    }
    
    func process(ticker: MarketTicker) {

    }
    
    func process(trade: MarketAggregatedTrade) {
        marketAnalyzer.record(trade)
        decide(price: trade.price)
    }
    
    func process(depthUpdate: MarketDepth) {
        
    }
    
    func decide(price: Double) {
        print("[\(DateFactory.now)] Must decide with price \(price)")
        guard marketAnalyzer.hasRecordFromAtLeastPastInterval(TimeInterval.fromMinutes(60)) else { return }
        
        //        let s = marketAnalyzer.prices(last: 3600)
        
        
        // Should buy?
        
        decideIfBuy(price: price)
        
        let marketLast30 = marketAnalyzer.prices(last: 30)
        
        // should sell
        for order in orders {
            if (price / order.price) > 1.01 && marketLast30.slope() < -3 {
                // let slope = marketAnalyzer.slope(last: 60)
                self.sell(order: order, at: price)
            }
        }
    }
    
    func decideIfBuy(price: Double) {
        
        //        Performance.measure(title: "All decision") {
        
        //        Performance.measure(title: "Market", code: { () in
        //            let tt = marketAnalyzer.prices(last: TimeInterval.fromMinutes(5))
        //            let ff = marketAnalyzer.prices(last: TimeInterval.fromMinutes(10))
        //            let dd = marketAnalyzer.prices(last: TimeInterval.fromMinutes(30))
        //            let ss = marketAnalyzer.prices(last: TimeInterval.fromMinutes(60))
        //        })
        
        
        
        let market5Last = marketAnalyzer.prices(last: TimeInterval.fromMinutes(5))
        let market10Last = marketAnalyzer.prices(last: TimeInterval.fromMinutes(10))
        let market30Last = marketAnalyzer.prices(last: TimeInterval.fromMinutes(30))
        let market60Last = marketAnalyzer.prices(last: TimeInterval.fromMinutes(60))
        
        let slope5Minutes = market5Last.slope()
        let variability5Minutes = market5Last.variability()
        
        let slope30Minutes = market30Last.slope()
        let variability30Minutes = market30Last.variability()
        //
        //let slope60Minutes = marketAnalyzer.slope(last: TimeInterval.fromMinutes(60))
        let variability60Minutes = market60Last.variability()
        
        //        Performance.measure(title: "Slope", code: { () in
        //            let fd = market5Last.slope()
        //            let ass = market30Last.slope()
        //        })
        //
        //        Performance.measure(title: "Variability", code: { () in
        //            let a = market30Last.variability()
        //            let b = market5Last.variability()
        //            let c = market60Last.variability()
        //        })
        
        if canBuy && price < variability60Minutes.max * 0.99 {
            
            if slope5Minutes > price / 1000 {
                // Slight increase
                // Must be very variable!
                if (variability5Minutes.variabilityRatioToPrice >= 0.5 / 100 && variability60Minutes.spikes07Percent >= 1) {
                    self.buy(price: price)
                    return
                }
            }
            
            if slope30Minutes < -1 {
                // Going down
                // Must be very variable!!
                if variability30Minutes.spikes1Percent > 1 && variability5Minutes.spikes07Percent > 1 {
                    self.buy(price: price)
                    return
                }
            }
            
            if (variability60Minutes.variabilityRatioToPrice > 1 / 100 && variability60Minutes.spikes1Percent > 2) {
                self.buy(price: price)
                return
            }
            
//            let var10 = market10Last.variability()
            let avg10 = market10Last.average()
            if (avg10 - price) / avg10 > (0.5 / 100.0) {
                self.buy(price: price)
                return
            }
            
            if (!orders.contains(where: {DateFactory.now - $0.date < TimeInterval.fromHours(1)})) {
                self.buy(price: price)
                return
            }
            
            let avg30 = variability30Minutes.average
            if (price - avg30) / avg30 > (0.3 / 100.0) && (variability30Minutes.max - price) / price > 0.3 * 100 {
                self.buy(price: price)
                return
            }
            
            //            if price < variability5Minutes.min {
            //                self.buy(price: price)
            //                return
            //            }
            
            if (variability5Minutes.average - price <= -100 && variability30Minutes.spikes1Percent > 0) {
                self.buy(price: price)
                return
            }
            
            //            let avg1 = mark
            //            if (avg10 > price)
        }
        //        }
    }
    
    func buy(price: Double) {
        
        balance -= orderSize
        
        let qty = (orderSize / price) * (1 - fees)
        let order = Order(date: DateFactory.now, price: price, qty: qty)
        self.orders.append(order)
        
        print("At \(DateFactory.now) Bought \(qty) for \(price)")
    }
    
    func sell(order: Order, at price: Double) {
        
        let sellCost = (order.qty * price) * (1 - fees)
        let sellProfits = sellCost - orderSize
        profits += sellProfits
        balance += sellCost
        self.orders.removeAll(where: {$0.date == order.date})
        
        print("Selling order made at \(order.date) for price \(order.price) at price \(price) for a total cost of \(sellCost) with profits of \(sellProfits). Total profits: \(profits).")
    }
}
