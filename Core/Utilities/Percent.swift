//

import Foundation

infix operator -% : AdditionPrecedence
infix operator +% : AdditionPrecedence


struct Percent: Comparable, CustomStringConvertible {

    /// The percentage.
    var percentage: Decimal
    
    /// The value represented by the percentage.
    var value: Decimal {
        return percentage / 100.0
    }
    
    init(_ percentage: Double) {
        self.percentage = Decimal(percentage)
    }
    
    init(_ percentage: Decimal) {
        self.percentage = percentage
    }
    
    init(ratioOf: Decimal, to: Decimal) {
        self.percentage = ratioOf / to * Decimal(100.0)
    }
    
    /// The  difference between a number compared to another original one.
    /// (1 - differenceOf / from) * 100
    init(differenceOf: Decimal, from: Decimal) {
        self.percentage = (differenceOf / from - 1) * 100
    }
    
    static func <(lhs: Percent, rhs: Percent) -> Bool {
        return lhs.percentage < rhs.percentage
    }
    
    static func ==(lhs: Percent, rhs: Percent) -> Bool {
        return lhs.value == rhs.value
    }
    
    // Operations Decimal then Percent

    static func *(lhs: Decimal, rhs: Percent) -> Decimal {
        return lhs * rhs.value
    }

    static func +%(lhs: Decimal, rhs: Percent) -> Decimal {
        return lhs * (rhs + Percent(100))
    }

    static func -%(lhs: Decimal, rhs: Percent) -> Decimal {
        return lhs * (Percent(100) - rhs)
    }

    // Operations  between Percents

    static func -(lhs: Percent, rhs: Percent) -> Percent {
        return Percent(lhs.percentage - rhs.percentage)
    }

    static func +(lhs: Percent, rhs: Percent) -> Percent {
        return Percent(lhs.percentage + rhs.percentage)
    }

    // Operations Percent then Double

    static func *(lhs: Percent, rhs: Decimal) -> Decimal {
        return lhs.value * rhs
    }
    
    static func /(lhs: Percent, rhs: Decimal) -> Percent {
        Percent(lhs.percentage / rhs)
    }
    
    var description: String {
        return "\(percentage.format(decimals: 4))%"
    }
}

extension Percent: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    init(integerLiteral value: IntegerLiteralType) {
        self.init(Decimal(value))
    }

    init(floatLiteral value: FloatLiteralType) {
        self.init(Decimal(value))
    }
}


