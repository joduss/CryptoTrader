//

import XCTest

class TechnicalIndicatorTests: XCTestCase {
    
    override func setUp() {
        continueAfterFailure = false
    }

    func testMAE() throws {
        
        let periods = 3
        

        let data: [Double] = [2,4,6,8,12,14,16,18,20.0]
        let expected: [Double] = [2,3,4.5,6.25,9.125,11.563,13.781,15.891,17.945]
        
        let mae = EMAIndicator(period: periods)
        let computed = mae.compute(on: data)
        
        XCTAssertEqual(expected.count, computed.count)
        
        var idx = 0
        while idx < data.endIndex {
            XCTAssertEqual(expected[idx], computed[idx], accuracy: 0.001)
            idx += 1
        }
    }

}
