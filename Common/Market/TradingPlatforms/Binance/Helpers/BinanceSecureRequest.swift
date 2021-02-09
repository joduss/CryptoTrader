import Foundation

class BinanceRequestPreparator {
    
    private let config: BinanceApiConfiguration
    
    init(config: BinanceApiConfiguration) {
        self.config = config
    }
    
    func addApiKey(to request: inout URLRequest) {
        request.addValue(config.key, forHTTPHeaderField: "X-MBX-APIKEY")
    }
    
    func signal(request: inout URLRequest) {
        
    }
    
}
