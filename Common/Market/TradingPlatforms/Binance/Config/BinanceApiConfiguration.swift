import Foundation

public class BinanceApiConfiguration {
    let key: String
    let secret: String
    var demo = false
    
    init(key: String, secret: String) {
        self.key = key
        self.secret = secret
    }
    
    var urls: BinanceApiUrls {
        if demo {
            return BinanceApiTestUrls()
        }
        return BinanceApiRealUrls()
    }
}
