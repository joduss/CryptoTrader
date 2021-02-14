import Foundation

import Foundation

struct BinanceUserDataStreamKeepAliveRequest: BinanceApiRequest {
    
    typealias Response = BinanceEmptyResponse

    let security: RequestSecurity = .signed
    let method: HttpMethod = .put
    let resource = "/api/v3/userDataStream"
    let queryItems: [URLQueryItem]?

    init(listenKey: String) {
        queryItems = [URLQueryItem(name: "listenKey", value: listenKey)]
    }
}
