import Foundation

func round(_ number: Decimal, numberOfDecimals: Int) -> Decimal {
    let multiplicator = (pow(10, numberOfDecimals) as NSNumber).decimalValue
    return round(number * multiplicator) / multiplicator
}

func round(_ number: Decimal) -> Decimal {
    var numberToRound = number
    var roundedNumber: Decimal = 0
    
    withUnsafeMutablePointer(to: &roundedNumber, {
        roundedNumberPointer in
        withUnsafePointer(to: &numberToRound, { numberToRoundPointer in
            NSDecimalRound(roundedNumberPointer, numberToRoundPointer, 0, .plain)
        })
    })
    
    return roundedNumber
}

func log10(_ number: Decimal) -> Decimal {
    return Decimal(log10((number as NSDecimalNumber).doubleValue))
}


func floor(_ number: Decimal) -> Decimal {
    var numberToRound = number
    var roundedNumber: Decimal = 0
    
    withUnsafeMutablePointer(to: &roundedNumber, {
        roundedNumberPointer in
        withUnsafePointer(to: &numberToRound, { numberToRoundPointer in
            NSDecimalRound(roundedNumberPointer, numberToRoundPointer, 0, .down)
        })
    })
    
    return roundedNumber
}

func ceil(_ number: Decimal) -> Decimal {
    var numberToRound = number
    var roundedNumber: Decimal = 0
    
    withUnsafeMutablePointer(to: &roundedNumber, {
        roundedNumberPointer in
        withUnsafePointer(to: &numberToRound, { numberToRoundPointer in
            NSDecimalRound(roundedNumberPointer, numberToRoundPointer, 0, .up)
        })
    })
    
    return roundedNumber
}
