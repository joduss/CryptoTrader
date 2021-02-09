import Foundation

class BinanceUserDataStream: BinanceApiFragment, UserDataStream {
    
    private let requestPreparator: BinanceRequestPreparator
    private(set) var subscribed: Bool = false
    private(set) var webSocketHandler: WebSocketHandler
    
    private var listenKey: String?
    
    override init(symbol: MarketPair, config: BinanceApiConfiguration) {
        requestPreparator = BinanceRequestPreparator(config: config)
        
        webSocketHandler = WebSocketHandler()
        
        super.init(symbol: symbol, config: config)
    }
    
    func subscribe() {
        createListenKey(completionHandler: { listenKey in
            self.listenKey = listenKey
        })
    }
    
    private func createListenKey(completionHandler: @escaping (String) -> ()) {
        var request = URLRequest(url: config.urls.userDataListenKeyURL)
        requestPreparator.addApiKey(to: &request)
        
        request.httpMethod = "POST"
        
        let task = URLSession(configuration: URLSessionConfiguration.default).dataTask(with: request, completionHandler: {
            data, response, errorRequest in
            if let errorRequest = errorRequest {
                print("Request listen key failed due to \(errorRequest)")
            }
            guard let data = data else {
                print("Request listen key failed due to nil data.")
                return
            }
            do {
                let response = try JSONDecoder().decode(BinanceListenKeyResponse.self, from: data)
                completionHandler(response.listenKey)
            }
            catch {
                print("Request listen key failed to parse data: \(error).")
            }
        })
        
        task.resume()
    }
    
    private func openStream() {
        
    }
}
