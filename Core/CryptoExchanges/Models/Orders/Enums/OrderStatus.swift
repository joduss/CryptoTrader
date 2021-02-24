import Foundation


enum OrderStatus: String, Codable {
    case new
    case partiallyFilled
    case filled
    case cancelled
    case rejected
    case expired
}
