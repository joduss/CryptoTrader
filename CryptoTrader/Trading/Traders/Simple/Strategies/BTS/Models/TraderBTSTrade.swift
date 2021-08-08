import Foundation

struct TraderBTSTrade: Codable {
    
    var price: Double
    var quantity: Double
    var value: Double
    var date: Date
    
    init(price: Double, quantity: Double, value: Double, now: Date) {
        self.date = now
        self.price = price
        self.quantity = quantity
        self.value = value
    }
}
