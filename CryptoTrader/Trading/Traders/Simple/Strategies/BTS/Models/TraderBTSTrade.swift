import Foundation

struct TraderBTSTrade: Codable {
    
    var price: Decimal
    var quantity: Decimal
    var value: Decimal
    var date: Date
    
    init(price: Decimal, quantity: Decimal, value: Decimal, now: Date) {
        self.date = now
        self.price = price
        self.quantity = quantity
        self.value = value
    }
}
