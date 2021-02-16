import Foundation

struct TraderBTSTrade {
    
    let price: Double
    let quantity: Double
    let value: Double
    let date: Date
    
    init(price: Double, quantity: Double, value: Double) {
        self.date = DateFactory.now
        self.price = price
        self.quantity = quantity
        self.value = value
    }
}
