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
    
    mutating func updateBids(at priceLevel: Double, with quantity: Double) {
        date = Date()
        if quantity == 0 {
            bidsDouble.removeValue(forKey: NSNumber(value: priceLevel))
            return
        }
        
        guard shouldAdd(at: priceLevel) else { return }
        
        bidsDouble[NSNumber(value: priceLevel)] = quantity
        bids = computeBids()
    }
    
    mutating func updateAsks(at priceLevel: Double, with quantity: Double) {
        date = Date()
        if quantity == 0 {
            asksDouble.removeValue(forKey: NSNumber(value: priceLevel))
            return
        }
        guard shouldAdd(at: priceLevel) else { return }
        
        asksDouble[NSNumber(value: priceLevel)] = quantity
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
            let roundedLevel: String = self.numberFormatter.string(for: priceLevel)!
            
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
        return price <= 1.5 * currentPrice && price >= 0.5 * currentPrice
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
}
