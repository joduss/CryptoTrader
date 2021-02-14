import Foundation

enum HttpMethod: String {
    case put = "PUT"
    case get = "GET"
    case post = "POST"
}

enum RequestSecurity {
    case none
    case signed
    case authenticated
}

protocol BinanceApiRequest {
    associatedtype Response: Decodable
    
    var security: RequestSecurity { get }
    var method: HttpMethod { get }
    var resource: String { get }
    var queryItems: [URLQueryItem]? { get }
}
