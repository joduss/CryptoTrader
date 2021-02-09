import Foundation


// https://api.binance.com/api    https://testnet.binance.vision/api
// wss://stream.binance.com:9443/ws    wss://testnet.binance.vision/ws
// wss://stream.binance.com:9443/stream    wss://testnet.binance.vision/stream

struct BinanceApiTestUrls: BinanceApiUrls {
    let baseUrl = URL(string: "")!
    let baseWssUrl = URL(string: "")!

    var userKeyURL: URL {
        return self.baseUrl.appendingPathComponent("/api/v3/userDataStream")
    }
}

struct BinanceApiRealUrls: BinanceApiUrls {
    let baseUrl = URL(string: "https://api.binance.com")!
    let baseWssUrl = URL(string: "wss://stream.binance.com:9443/ws")!

    var userKeyURL: URL {
        return self.baseUrl.appendingPathComponent("/api/v3/userDataStream")
    }
}

protocol BinanceApiUrls {
    var baseUrl: URL { get }
    var baseWssUrl: URL { get }
    var userKeyURL: URL { get }
}
