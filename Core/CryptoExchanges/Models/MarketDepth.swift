import Foundation

public struct MarketDepthBackup: Codable {
    
    public let date: Date
    public let id: Int
    public private(set) var bids: [String : Decimal] = [:]
    public private(set) var asks: [String : Decimal] = [:]
    
    public var bidsDoubles: [Decimal : Decimal] {
        var transformedBids = [Decimal : Decimal]()
        transformedBids.reserveCapacity(bids.count)
        for (key, value) in self.bids {
            transformedBids[Decimal(key)!] = value
        }
        return transformedBids
    }
    
    public var asksDoubles: [Decimal : Decimal] {
        var transformedAsks = [Decimal : Decimal]()
        transformedAsks.reserveCapacity(asks.count)
        for (key, value) in self.asks {
            transformedAsks[Decimal(key)!] = value
        }
        return transformedAsks
    }
    
    init(bids: [Decimal : Decimal], asks: [Decimal : Decimal], date: Date, id: Int) {
        self.bids.reserveCapacity(bids.count)
        self.asks.reserveCapacity(asks.capacity)
        self.date = date
        self.id = id
        
        for (bidKey, bidValue) in bids {
            self.bids[bidKey.description] = bidValue
        }
        
        for (askKey, askValue) in asks {
            self.asks[askKey.description] = askValue
        }
    }
}


public struct MarketDepth: Codable {
    
    public private(set) var id: Int
    public private(set) var date = Date()
    public private(set) var bids: [Decimal : Decimal] = [:]
    public private(set) var asks: [Decimal : Decimal] = [:]
    
    private var numberFormatter: NumberFormatter

    public var currentPrice: Decimal = 0 {
        didSet {
            clean()
        }
    }

    enum CodingKeys: String, CodingKey {
        case bids
        case asks
        case date
        case id
    }
    
    // MARK: - Initialization and serialization
    
    public init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        date = try values.decode(Date.self, forKey: .date)
        id = try values.decode(Int.self, forKey: .id)
        
        let bidsString = try values.decode([String : String].self, forKey: .bids)
        let asksString = try values.decode([String : String].self, forKey: .asks)
        
        bids.reserveCapacity(bidsString.count)
        for bidString in bidsString {
            bids[Decimal(bidString.key)!] = Decimal(bidString.value)!
        }
        
        asks.reserveCapacity(asks.count)
        for askString in asksString {
            asks[Decimal(askString.key)!] = Decimal(askString.value)!
        }
    }
    
    public init() {
        id = 0
        numberFormatter = NumberFormatter()
        numberFormatter.usesSignificantDigits = true
        numberFormatter.maximumSignificantDigits = 6
    }
    
    public init(marketDepthBackup: MarketDepthBackup) {
        self.init()
        self.bids = marketDepthBackup.bidsDoubles
        self.asks = marketDepthBackup.asksDoubles
        self.date = marketDepthBackup.date
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bidsAsStrings(), forKey: .bids)
        try container.encode(asksAsStrings(), forKey: .asks)
        try container.encode(date, forKey: .date)
        try container.encode(id, forKey: .id)
    }
    
    public func backup() -> MarketDepthBackup {
        return MarketDepthBackup(bids: self.bids, asks: self.asks, date: self.date, id: self.id)
    }
    
    
    // MARK: - Data update
    mutating func updateId(_ id: Int) {
        self.id = id
    }
    
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
                let currentQty = Decimal(newBidsString[roundedLevel]!)!
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
                let currentQty = Decimal(newAsksString[roundedLevel]!)!
                newAsksString[roundedLevel] = numberFormatter.string(from: roundQuantity(currentQty + qty))!
            }
            else {
                newAsksString[roundedLevel] = numberFormatter.string(from: roundQuantity(qty))!
            }
        }
        
        return newAsksString
    }
    
    private func shouldAdd(at price: Decimal) -> Bool {
        return price <= 1.5 * currentPrice && price >= currentPrice / 1.5
    }
    
    // MARK: - Helpers
    
    /// Round a price adaptively. There is more resolution close to the current price than far away.
    func adaptivePriceRound(_ priceToRound: NSNumber) -> Decimal {
        return adaptivePriceRound(priceToRound.decimalValue)
    }
    
    func adaptivePriceRound(_ priceToRound: Decimal) -> Decimal {
        
        guard currentPrice != 0 else { return priceToRound }
        
        let rangeVeryPrecise = currentPrice / 250 // 120
        let rangePrecise = currentPrice / 100 // 300
        let rangeLessPrecise = currentPrice / 20 // 1500
        let rangeNotPrecise = currentPrice / 5 // 6000
        
        let significantDigits = 5.0
        let numberOrder = (floor(log10(currentPrice)) as NSDecimalNumber).doubleValue
        var orderCorrected = Decimal(pow(10, 1 + numberOrder - significantDigits))
        orderCorrected = orderCorrected * currentPrice / pow(10,Int(numberOrder))
        
        if priceToRound >= currentPrice - rangeVeryPrecise && priceToRound <= currentPrice + rangeVeryPrecise {
            return roundPrice(priceToRound, roundBase: orderCorrected * 1.0)
        }
        else if priceToRound >= currentPrice - rangePrecise && priceToRound <= currentPrice + rangePrecise {
            return roundPrice(priceToRound, roundBase: orderCorrected * 5.0)
        }
        else if priceToRound >= currentPrice - rangeLessPrecise && priceToRound <= currentPrice + rangeLessPrecise {
            return roundPrice(priceToRound, roundBase: orderCorrected * 25.0)
        }
        else if priceToRound >= currentPrice - rangeNotPrecise && priceToRound <= currentPrice + rangeNotPrecise {
            return roundPrice(priceToRound, roundBase: orderCorrected * 50.0)
        }
        else {
            return roundPrice(priceToRound, roundBase: orderCorrected * 150.0)
        }
    }
    
    /// Round a price to a certain base. If base is 15, then it will ve rounded to a multiple of 15.
    func roundPrice(_ number: Decimal, roundBase: Decimal) -> Decimal {
        return round(number / roundBase) * roundBase
    }
    
    func roundQuantity(_ quantity: Decimal) -> Decimal {
        if currentPrice == 0 {
            return quantity
        }
        
        return round(quantity, numberOfDecimals: (ceil(2 + log10(currentPrice)) as NSDecimalNumber).intValue)
    }
 }
