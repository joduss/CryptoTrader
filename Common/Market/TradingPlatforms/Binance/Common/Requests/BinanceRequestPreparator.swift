import Foundation
import CryptoKit

public class BinanceRequestPreparator {
    
    private let config: BinanceApiConfiguration
    private lazy var encryptionKey: SymmetricKey = {
        return SymmetricKey(data: config.secret.data(using: .utf8)!)
    }()
    
    public init(config: BinanceApiConfiguration) {
        self.config = config
    }
    
    public func addApiKey(to request: inout URLRequest) {
        request.addValue(config.key, forHTTPHeaderField: "X-MBX-APIKEY")
    }
    
    public func signQueryString(request: inout URLRequest) {
        
        addApiKey(to: &request)
        
        var requestComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: true)!
        
        if (requestComponents.queryItems == nil) {
            requestComponents.queryItems = []
        }
        
        requestComponents.queryItems!.append(URLQueryItem(name: "timestamp", value: "\(Int(Date().timeIntervalSince1970) * 1000)"))

        
        let authCode = HMAC<SHA256>.authenticationCode(for: requestComponents.query!.data(using: .utf8)!, using: encryptionKey)
        let signature = Data(authCode).hexString
    
        var items: [URLQueryItem] = requestComponents.queryItems!
        items.append(URLQueryItem(name: "signature", value: signature))
        requestComponents.queryItems = items
        
        request.url = requestComponents.url!
        
    }
    
}
