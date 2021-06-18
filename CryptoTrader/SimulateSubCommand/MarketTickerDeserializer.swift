import Foundation
import JoLibrary

class MarketTickerDeserializer {
    
    class func loadTickers(from file: String, startIdx: Int, endIdx: Int) -> ContiguousArray<MarketTicker> {
        let reader = TextFileReader.openFile(at: file)
        var idx = 0
        let keepEveryNTicker = 20
        
        var tickers = ContiguousArray<MarketTicker>()
        tickers.reserveCapacity(100000000)
        
        while true {
            
            guard let line: String = reader.readLine() else {
                break
            }
            
            idx += 1
            
            if (idx % 1000000 == 0) { print(idx) }
            if idx < startIdx { continue }
            if idx > endIdx { break }
            if (idx % keepEveryNTicker != 0) { continue }
            
            let ticker = MarketTickerDeserializer.parse(line: line)
            
            tickers.append(ticker)
        }
        
        return tickers
    }
    
    //"{"symbol":"BTCUSDT","id":8611636536,"date":634547549.01567698,"bidQuantity":186.18478599999997,"askPrice":47650.879999999997,"bidPrice":47650.870000000003,"askQuantity":2.9338730000000006}"
    private static func parse(line: String) -> MarketTicker {
        var symbol: CryptoSymbol!
        var id: Int!
        var date: Date!
        var bidQty: Decimal!
        var askPrice: Decimal!
        var bidPrice: Decimal!
        var askQuantity: Decimal!
        
        var elementIdx = 0
        var accumulated = ""
        var accumulating = false
        
        for char in line {
            if accumulating == false && char == ":" {
                accumulating = true
                accumulated = ""
                accumulated.reserveCapacity(20)
                continue
            }
            else if accumulating == false {
                continue
            }
            
            if char != "," && char != "}" {
                if char == "\"" { continue }
                accumulated.append(char)
                continue
            }
            
            switch elementIdx {
                case 0:
                    symbol = .btc_usd
                    break
                case 1:
                    id = Int(accumulated)
                    break
                case 2:
                    date = Date(timeIntervalSinceReferenceDate: TimeInterval(accumulated)!)
                    break
                case 3:
                    bidQty = Decimal(string: accumulated)!
                    break
                case 4:
                    askPrice = Decimal(string: accumulated)!
                    break
                case 5:
                    bidPrice = Decimal(string: accumulated)!
                    break
                case 6:
                    askQuantity = Decimal(string: accumulated)!
                    break
                default:
                    break
            }
            
            accumulating = false
            elementIdx += 1
        }
        
        return MarketTicker(id: id, date: date, symbol: symbol.rawValue, bidPrice: bidPrice, bidQuantity: bidQty, askPrice: askPrice, askQuantity: askQuantity)
    }
    
}
