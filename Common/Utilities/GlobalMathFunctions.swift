import Foundation

func round(_ number: Double, numberOfDecimals: Int) -> Double {
    let multiplicator = (pow(10, numberOfDecimals) as NSNumber).doubleValue
    return round(number * multiplicator) / multiplicator
}
