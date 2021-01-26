//

import XCTest

class CryptoTraderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPercent() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let percent = Percent(25)
        
        XCTAssertEqual(25, percent.percentage)
        XCTAssertEqual(0.25, percent.value)
                
        XCTAssertEqual(50, 40 +% percent)
        XCTAssertEqual(30, 40 -% percent)
        XCTAssertEqual(10, 40 * percent)
        XCTAssertEqual(10, percent * 40)

        XCTAssertEqual(Percent(55), (percent + Percent(30)))
        XCTAssertEqual(Percent(20), (percent - Percent(5)))
        
        XCTAssertEqual(Percent(25), percent)
        
        XCTAssertEqual(-20, Percent(differenceOf: 80, from: 100).percentage, accuracy: 10e-5)
        XCTAssertEqual(25, Percent(differenceOf: 250, from: 200).percentage, accuracy: 10e-5)

        XCTAssertEqual(Percent(50), Percent(ratioOf: 100, to: 200))
        XCTAssertEqual(Percent(200), Percent(ratioOf: 200, to: 100))

//        XCTAssertEqual(<#T##expression1: FloatingPoint##FloatingPoint#>, <#T##expression2: FloatingPoint##FloatingPoint#>, accuracy: <#T##FloatingPoint#>)
        
    }
}
