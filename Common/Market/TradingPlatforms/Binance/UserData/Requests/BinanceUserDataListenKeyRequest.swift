import Foundation

struct BinanceUserDataListenKeyRequest: BinanceApiRequest {
    typealias Response = BinanceUserDataStreamListenKeyResponse

    let security: RequestSecurity = .signed
    let method: HttpMethod = .post
    let resource: String = "/api/v3/userDataStream"
    let queryItems: [URLQueryItem]? = nil
}
