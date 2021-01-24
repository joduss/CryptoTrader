import Foundation

public struct MarketDepth: Codable {
    
    public private(set) var date = Date()
    public private(set) var bids: [String : String] = [:]
    public private(set) var asks: [String : String] = [:]
    
    private var bidsDouble: [NSNumber : Double] = [:]
    private var asksDouble: [NSNumber : Double] = [:]
    
    public var currentPrice: Double = 0 {
        didSet {
            clean()
        }
    }

    enum CodingKeys: String, CodingKey {
        case bids
        case asks
        case date
    }
    
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 4
        return formatter
    }()
    
    mutating func updateBids(_ depthElements: [MarketDepthElement]) {
        date = Date()
        
        for depthElement in depthElements {
            if depthElement.quantity == 0 {
                bidsDouble.removeValue(forKey: NSNumber(value: depthElement.priceLevel))
                continue
            }
            
            guard shouldAdd(at: depthElement.priceLevel) else { continue }
            
            bidsDouble[NSNumber(value: depthElement.priceLevel)] = depthElement.quantity
        }
        
        bids = computeBids()
    }
    
    mutating func updateAsks(_ depthElements: [MarketDepthElement]) {
        date = Date()
        
        for depthElement in depthElements {
            if depthElement.quantity == 0 {
                asksDouble.removeValue(forKey: NSNumber(value: depthElement.priceLevel))
                continue
            }
            guard shouldAdd(at: depthElement.priceLevel) else { continue }
            
            asksDouble[NSNumber(value: depthElement.priceLevel)] = depthElement.quantity
        }
        asks = computeAsks()
    }
    
    private mutating func computeBids() -> [String : String] {
        
        var bids = [String:String]()
        
        for (priceLevel, qty) in bidsDouble {
            let roundedLevel: String = self.numberFormatter.string(for: priceLevel)!
            
            if bids.keys.contains(roundedLevel) {
                let currentQty = Double(bids[roundedLevel]!)!
                bids[roundedLevel] = String(currentQty + qty)
            }
            else {
                bids[roundedLevel] = qty.description
            }
        }
        
        return bids
    }
    
    private mutating func computeAsks() -> [String : String] {
        
        var asks = [String:String]()
        
        for (priceLevel, qty) in asksDouble {
            let roundedLevel: String = self.numberFormatter.string(for: adaptivePriceRound(priceLevel))!
            
            if asks.keys.contains(roundedLevel) {
                let currentQty = Double(asks[roundedLevel]!)!
                asks[roundedLevel] = String(currentQty + qty)
            }
            else {
                asks[roundedLevel] = qty.description
            }
        }
        
        return asks
    }
    
    private func shouldAdd(at price: Double) -> Bool {
        return price <= 1.5 * currentPrice && price >= currentPrice / 1.5
    }

    private mutating func clean() {
        
        let asksToRemove = asksDouble.keys.filter({shouldAdd(at: $0.doubleValue) == false})
        let bidsToRemove = bidsDouble.keys.filter({shouldAdd(at: $0.doubleValue) == false})

        for askToRemove in asksToRemove {
            asksDouble.removeValue(forKey: askToRemove)
        }
        
        for bidToRemove in bidsToRemove {
            bidsDouble.removeValue(forKey: bidToRemove)
        }
    }
    
    // MARK: - Helpers
    
    /// Round a price adaptively. There is more resolution close to the current price than far away.
    func adaptivePriceRound(_ number: NSNumber) -> Double {
        
        let priceValue = number.doubleValue
        
        guard currentPrice != 0 else { return priceValue}
        
        let rangeVeryPrecise = currentPrice / 200
        let rangePrecise = currentPrice / 10
        
        if priceValue >= currentPrice - rangeVeryPrecise && priceValue <= currentPrice + rangeVeryPrecise {
            return roundPrice(priceValue, roundBase: round(currentPrice / 10000.0) * 1.0)
        }
        else if priceValue >= currentPrice - rangePrecise && priceValue <= currentPrice + rangePrecise {
            return roundPrice(priceValue, roundBase: round(currentPrice / 10000.0) * 5.0)
        }
        else {
            return roundPrice(priceValue, roundBase: round(currentPrice / 10000.0) * 25.0)
        }
    }

    /// Round a price to a certain base. If base is 15, then it will ve rounded to a multiple of 15.
    func roundPrice(_ number: Double, roundBase: Double) -> Double {
        return round(number / roundBase) * roundBase
    }
}
