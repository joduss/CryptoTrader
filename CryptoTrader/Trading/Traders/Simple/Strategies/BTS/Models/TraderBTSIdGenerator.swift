import Foundation

struct TraderBTSIdGenerator {
    
    var id: String
    var date: Date
    var action: String
    var price: Double
    
    func generate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ddMM-HHmmss"
        
        let numberFormatter = NumberFormatter()
        numberFormatter.usesSignificantDigits = true
        numberFormatter.maximumSignificantDigits = 6
        numberFormatter.minimumSignificantDigits = 1
        
        // SELL_AA3C_2212_235512_34543-5
        let idString = "\(action)_\(id)_\(formatter.string(from: date))_\(numberFormatter.string(from: price)!)"
        
        return idString.replacingOccurrences(of: ".", with: "-").truncate(length: 32)
    }
}
