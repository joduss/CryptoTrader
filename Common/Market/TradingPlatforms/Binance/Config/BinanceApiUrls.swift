import Foundation


// https://api.binance.com/api    https://testnet.binance.vision/api
// wss://stream.binance.com:9443/ws    wss://testnet.binance.vision/ws
// wss://stream.binance.com:9443/stream    wss://testnet.binance.vision/stream

struct BinanceApiTestUrls: BinanceApiUrls {
    let baseUrl = URL(string: "https://testnet.binance.vision")!
    let baseWssUrl = URL(string: "wss://testnet.binance.vision/ws")!
}

struct BinanceApiRealUrls: BinanceApiUrls {
    let baseUrl = URL(string: "https://api.binance.com")!
    let baseWssUrl = URL(string: "wss://stream.binance.com:9443/ws")!
}

protocol BinanceApiUrls {
    var baseUrl: URL { get }
    var baseWssUrl: URL { get }
    var userDataListenKeyURL: URL { get }
}

extension BinanceApiUrls {
    var userDataListenKeyURL: URL {
        return self.baseUrl.appendingPathComponent("/api/v3/userDataStream")
    }
    
    var userDataStreamURL: URL {
        return self.baseWssUrl.appendingPathComponent("")
    }
}
