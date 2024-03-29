//

import Foundation

infix operator -% : AdditionPrecedence
infix operator +% : AdditionPrecedence
infix operator % : MultiplicationPrecedence


struct Percent: Comparable, CustomStringConvertible {

    /// The percentage.
    var percentage: Double
    
    /// The value represented by the percentage.
    var value: Double {
        return percentage / 100.0
    }
    
    init(_ percentage: Double) {
        self.percentage = percentage
    }
    
    init(_ percentage: Decimal) {
        self.percentage = percentage.doubleValue
    }
    
    init(ratioOf: Double, to: Double) {
        self.percentage = ratioOf / to * 100.0
    }
    
    /// The  difference between a number compared to another original one.
    /// (1 - differenceOf / from) * 100
    init(differenceOf: Double, from: Double) {
        self.percentage = (differenceOf / from - 1) * 100.0
    }
    
    static func <(lhs: Percent, rhs: Percent) -> Bool {
        return lhs.percentage < rhs.percentage
    }
    
    static func ==(lhs: Percent, rhs: Percent) -> Bool {
        return lhs.value == rhs.value
    }
    
    // Operations Decimal then Percent

    static func *(lhs: Double, rhs: Percent) -> Double {
        return lhs * rhs.value
    }

    static func +%(lhs: Double, rhs: Percent) -> Double {
        return lhs * (rhs + Percent(100))
    }

    static func -%(lhs: Double, rhs: Percent) -> Double {
        return lhs * (Percent(100) - rhs)
    }
    
    static func %(lhs: Double, rhs: Percent) -> Double {
        return lhs * (Percent(100) + rhs)
    }

    // Operations  between Percents

    static func -(lhs: Percent, rhs: Percent) -> Percent {
        return Percent(lhs.percentage - rhs.percentage)
    }

    static func +(lhs: Percent, rhs: Percent) -> Percent {
        return Percent(lhs.percentage + rhs.percentage)
    }

    // Operations Percent then Double

    static func *(lhs: Percent, rhs: Double) -> Double {
        return lhs.value * rhs
    }
    
    static func /(lhs: Percent, rhs: Double) -> Percent {
        Percent(lhs.percentage / rhs)
    }
    
    var description: String {
        return "\(percentage.format(decimals: 4))%"
    }
}

extension Percent: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    init(integerLiteral value: IntegerLiteralType) {
        self.init(Double(value))
    }

    init(floatLiteral value: FloatLiteralType) {
        self.init(Decimal(value))
    }
}


