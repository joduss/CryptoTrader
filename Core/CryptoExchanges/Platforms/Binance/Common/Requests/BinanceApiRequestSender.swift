import Foundation

class BinanceApiRequestSender {
    
    private let config: BinanceApiConfiguration
    private let requestPreparator: BinanceRequestPreparator
    
    init(config: BinanceApiConfiguration) {
        self.config = config
        self.requestPreparator = BinanceRequestPreparator(config: config)
    }
    
    func send<BRequest: BinanceApiRequest>(_ request: BRequest, completion: @escaping (Result<BRequest.Response, ExchangePlatformError>) -> ()) {
        
        var urlComponent = URLComponents(url: config.urls.baseUrl.appendingPathComponent(request.resource), resolvingAgainstBaseURL: false)
        urlComponent?.queryItems = request.queryItems
        
        var urlRequest = URLRequest(url: (urlComponent?.url!)!)
        
        switch request.security {
        case .signed:
            requestPreparator.signQueryString(request: &urlRequest)
        case .authenticated:
            requestPreparator.addApiKey(to: &urlRequest)
        case .none:
            break
        }
        
        switch request.method {
        case .get:
            urlRequest.httpMethod = "GET"
        case .post:
            urlRequest.httpMethod = "POST"
        case .put:
            urlRequest.httpMethod = "PUT"
        }
        
        URLSession(configuration: URLSessionConfiguration.ephemeral).dataTask(with: urlRequest) {
            data, response, error in
            if let error = error {
                completion(Result.failure(ExchangePlatformError.error(error: error)))
                return
            }
            
            if let data = data {
                do {
                    let parsed = try JSONDecoder().decode(BRequest.Response.self, from: data)
                    completion(.success(parsed))
                    return
                } catch {
                    completion(
                        .failure(
                            ExchangePlatformError.parsingError(message: "Parsing error \(error) while parsing \(String(data: data, encoding: .utf8) ?? "String representatin cannot be done.")")
                        )
                    )
                    return
                }
            }
            
            completion(.failure(ExchangePlatformError.generalError(message: "No error but not data...")))
        }
        .resume()
    }
}
