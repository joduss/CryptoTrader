import Foundation

protocol BinanceApiRequest {
    associatedtype Response: Decodable
    
    var security: BinanceRequestSecurity { get }
    var method: HttpMethod { get }
    var resource: String { get }
    var queryItems: [URLQueryItem]? { get }
}
