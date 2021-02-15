import Foundation

struct BinanceUserDataListenKeyRequest: BinanceApiRequest {
    typealias Response = BinanceUserDataStreamListenKeyResponse

    let security: BinanceRequestSecurity = .signed
    let method: HttpMethod = .post
    let resource: String = "/api/v3/userDataStream"
    let queryItems: [URLQueryItem]? = nil
}
