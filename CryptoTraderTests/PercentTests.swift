//

import XCTest
//@testable import CryptoTraderLib

class PercentTests: XCTestCase {

    func testPercent() throws {
        let percent = Percent(25)


        XCTAssertEqual(25, percent.percentage)
        XCTAssertEqual(0.25, percent.value)
                
        XCTAssertEqual(50, 40 +% percent)
        XCTAssertEqual(30, 40 -% percent)
        XCTAssertEqual(10, 40 * percent)
        XCTAssertEqual(10, percent * 40)
        XCTAssertEqual(44, 40 % Percent(10))
        XCTAssertEqual(36, 40 % Percent(-10))

        XCTAssertEqual(Percent(55), (percent + Percent(30)))
        XCTAssertEqual(Percent(20), (percent - Percent(5)))
        
        XCTAssertEqual(Percent(25), percent)
        
        XCTAssertEqual(-20, Percent(differenceOf: 80, from: 100).percentage, accuracy: 10e-5)
        XCTAssertEqual(25, Percent(differenceOf: 250, from: 200).percentage, accuracy: 10e-5)

        XCTAssertEqual(Percent(50), Percent(ratioOf: 100, to: 200))
        XCTAssertEqual(Percent(200), Percent(ratioOf: 200, to: 100))
        
        
    }
    
    func testExpressibleByFloatLiteral() throws {
        let percent = Percent(100)
        let decimalValue: Double = 150
        
        let decimalResult = decimalValue * percent
                
        XCTAssertEqual(decimalValue, decimalResult)
    }
}
