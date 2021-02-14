import Foundation

enum OrderExecutionType {
    case new
    case cancelled
    case replaced
    case rejected
    case trade // Part of the order or all of the order's quantity has filled.
    case expired
}
