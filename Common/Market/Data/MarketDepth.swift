import Foundation

public struct MarketDepth: Codable {
    
    public private(set) var date = Date()
    public private(set) var bids: [Double : Double] = [:]
    public private(set) var asks: [Double : Double] = [:]
    
    private var numberFormatter: NumberFormatter

    public var currentPrice: Double = 0 {
        didSet {
            clean()
        }
    }

    enum CodingKeys: String, CodingKey {
        case bids = "bids"
        case asks = "asks"
        case date
    }
    
    // MARK: - Initialization and serialization
    
    public init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        date = try values.decode(Date.self, forKey: .date)
        
        let bidsString = try values.decode([String : String].self, forKey: .bids)
        let asksString = try values.decode([String : String].self, forKey: .asks)
        
        bids.reserveCapacity(bidsString.count)
        for bidString in bidsString {
            bids[Double(bidString.key)!] = Double(bidString.value)!
        }
        
        asks.reserveCapacity(asks.count)
        for askString in asksString {
            asks[Double(askString.key)!] = Double(askString.value)!
        }
    }
    
    public init() {
        numberFormatter = NumberFormatter()
        numberFormatter.usesSignificantDigits = true
        numberFormatter.maximumSignificantDigits = 6
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let bidsStrings = bidsAsStrings()
        let asksStrings = asksAsStrings()
        try container.encode(bidsStrings, forKey: .bids)
        try container.encode(asksStrings, forKey: .asks)
        try container.encode(date, forKey: .date)
        sourcePrint("Serializing MarketDepth: It has \(asksStrings.count) asks aggregated levels and \(bidsStrings.count) bid aggregated levels")
    }
    
    
    // MARK: - Data update
    
    mutating func updateBids(_ depthElements: [MarketDepthElement]) {
        date = Date()
        
        for depthElement in depthElements {
            if depthElement.quantity == 0 {
                bids.removeValue(forKey: depthElement.priceLevel)
                continue
            }
            
            guard shouldAdd(at: depthElement.priceLevel) else { continue }
            
            bids[depthElement.priceLevel] = depthElement.quantity
        }
        
    }
    
    mutating func updateAsks(_ depthElements: [MarketDepthElement]) {
        date = Date()
        
        for depthElement in depthElements {
            if depthElement.quantity == 0 {
                asks.removeValue(forKey: depthElement.priceLevel)
                continue
            }
            guard shouldAdd(at: depthElement.priceLevel) else { continue }
            
            asks[depthElement.priceLevel] = depthElement.quantity
        }
    }
    
    private mutating func clean() {
        
        let asksToRemove = asks.keys.filter({shouldAdd(at: $0) == false})
        let bidsToRemove = bids.keys.filter({shouldAdd(at: $0) == false})

        for askToRemove in asksToRemove {
            asks.removeValue(forKey: askToRemove)
        }
        
        for bidToRemove in bidsToRemove {
            bids.removeValue(forKey: bidToRemove)
        }
    }
    
    // MARK: - Serialization helpers
    
    private func bidsAsStrings() -> [String : String] {
        
        var newBidsString = [String : String](minimumCapacity: bids.count / 5 + 1)
        
        for (priceLevel, qty) in bids {
            let roundedLevel: String = self.numberFormatter.string(for: adaptivePriceRound(priceLevel))!
            
            if newBidsString.keys.contains(roundedLevel) {
                let currentQty = Double(newBidsString[roundedLevel]!)!
                newBidsString[roundedLevel] = numberFormatter.string(from: roundQuantity(currentQty + qty))!
            }
            else {
                newBidsString[roundedLevel] = numberFormatter.string(from: roundQuantity(qty))!
            }
        }
        
        return newBidsString
    }
    
    private func asksAsStrings() -> [String : String] {
        
        var newAsksString = [String : String](minimumCapacity: asks.count / 5 + 1)

        for (priceLevel, qty) in asks {
            let roundedLevel: String = self.numberFormatter.string(for: adaptivePriceRound(priceLevel))!
            
            if newAsksString.keys.contains(roundedLevel) {
                let currentQty = Double(newAsksString[roundedLevel]!)!
                newAsksString[roundedLevel] = numberFormatter.string(from: roundQuantity(currentQty + qty))!
            }
            else {
                newAsksString[roundedLevel] = numberFormatter.string(from: roundQuantity(qty))!
            }
        }
        
        return newAsksString
    }
    
    private func shouldAdd(at price: Double) -> Bool {
        return price <= 1.5 * currentPrice && price >= currentPrice / 1.5
    }
    
    // MARK: - Helpers
    
    /// Round a price adaptively. There is more resolution close to the current price than far away.
    func adaptivePriceRound(_ priceToRound: NSNumber) -> Double {
        return adaptivePriceRound(priceToRound.doubleValue)
    }
    
    func adaptivePriceRound(_ priceToRound: Double) -> Double {
                
        guard currentPrice != 0 else { return priceToRound}
        
        let rangeVeryPrecise = currentPrice / 250 // 120
        let rangePrecise = currentPrice / 100 // 300
        let rangeLessPrecise = currentPrice / 20 // 1500
        let rangeNotPrecise = currentPrice / 5 // 6000
        
        if priceToRound >= currentPrice - rangeVeryPrecise && priceToRound <= currentPrice + rangeVeryPrecise {
            return roundPrice(priceToRound, roundBase: round(currentPrice / 10000.0) * 1.0)
        }
        else if priceToRound >= currentPrice - rangePrecise && priceToRound <= currentPrice + rangePrecise {
            return roundPrice(priceToRound, roundBase: round(currentPrice / 10000.0) * 5.0)
        }
        else if priceToRound >= currentPrice - rangeLessPrecise && priceToRound <= currentPrice + rangeLessPrecise {
            return roundPrice(priceToRound, roundBase: round(currentPrice / 10000.0) * 25.0)
        }
        else if priceToRound >= currentPrice - rangeNotPrecise && priceToRound <= currentPrice + rangeNotPrecise {
            return roundPrice(priceToRound, roundBase: round(currentPrice / 10000.0) * 50.0)
        }
        else {
            return roundPrice(priceToRound, roundBase: round(currentPrice / 10000.0) * 150.0)
        }
    }

    /// Round a price to a certain base. If base is 15, then it will ve rounded to a multiple of 15.
    func roundPrice(_ number: Double, roundBase: Double) -> Double {
        return round(number / roundBase) * roundBase
    }
    
    func roundQuantity(_ quantity: Double) -> Double {
        if currentPrice == 0 {
            return quantity
        }
        
        return round(quantity, numberOfDecimals: Int(ceil(2 + log10(currentPrice))))
    }
 }
