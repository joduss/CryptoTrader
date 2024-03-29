import Foundation

class BinanceUserDataStream: BinanceApiFragment, ExchangeUserDataStream, WebSocketDelegate {
    
    private let requestPreparator: BinanceRequestPreparator
    private(set) var subscribed: Bool = false
    private(set) var webSocketHandler: WebSocketHandler
    private let requestSender: BinanceApiRequestSender
    
    private var listenKey: String?
    
    weak var userDataStreamSubscriber: ExchangeUserDataStreamSubscriber?

    private var socket: WebSocket {
        return webSocketHandler.socket!
    }
    
    override init(symbol: CryptoSymbol, config: BinanceApiConfiguration) {
        requestPreparator = BinanceRequestPreparator(config: config)
        requestSender = BinanceApiRequestSender(config: config)
        webSocketHandler = WebSocketHandler()
        
        super.init(symbol: symbol, config: config)
    }
    
    func subscribeUserDataStream() {
        self.createListenKey(completionHandler: { listenKey in
            self.listenKey = listenKey
            sourcePrint("Listen key obtained. Creating the websocket")
            self.webSocketHandler.update(url: self.config.urls.userDataStreamWssUrl(listenKey: listenKey))
            self.webSocketHandler.websocketDelegate = self
            self.webSocketHandler.createSocket()
        })
    }
        
    private func createListenKey(completionHandler: @escaping (String) -> ()) {
      let request = BinanceUserDataListenKeyRequest()
        requestSender.send(request) {
            result in
            
            switch result {
            case let .failure(error):
                sourcePrint(String(describing: error))
                break
            case let .success(listenKeyResponse):
                self.listenKey = listenKeyResponse.listenKey
                self.sendKeepAlive()
                completionHandler(listenKeyResponse.listenKey)
            }
        } 
    }
    
    // MARK: - Keep Alive
    
    private func sendKeepAlive() {
        let request = BinanceUserDataStreamKeepAliveRequest(listenKey: self.listenKey!)
        requestSender.send(request) {
            result in
            
            switch result {
            case let .failure(error):
                sourcePrint(String(describing: error))
                break
            default:
                break
            }
            
            self.prepareNextKeepAlive()
        }
    }
    
    private func prepareNextKeepAlive() {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1000) { [self] in
            self.sendKeepAlive()
        }
    }
    
    // MARK - Stream processing
    
    func process(response: String) {
        do {
            try parse(response: response)
        } catch {
            sourcePrint("Parsing of the response \(response) failed. Error: \(error).")
        }
    }
    
    private func parse(response: String) throws {
        if (response.starts(with: "{\"e\":\"executionReport\"")) {
            let binanceReport = try JSONDecoder().decode(BinanceUserDataStreamExecutionOrderResponse.self, from: response.data(using: .utf8)!)
            
            let report = OrderExecutionReport(orderCreationTime: binanceReport.orderCreationTime,
                                              symbol: try BinanceSymbolConverter.convert(binanceReport.symbol),
                                              clientOrderId: binanceReport.clientOrderId,
                                              side: binanceReport.side,
                                              orderType: binanceReport.orderType,
                                              price: binanceReport.lastExecutedPrice,
                                              currentExecutionType: binanceReport.currentExecutionType,
                                              currentOrderStatus: binanceReport.currentOrderStatus,
                                              lastExecutedQuantity: binanceReport.lastExecutedQuantity,
                                              cumulativeFilledQuantity: binanceReport.cumulativeFilledQuantity,
                                              lastExecutedPrice: binanceReport.lastExecutedPrice,
                                              commissionAmount: binanceReport.commissionAmount,
                                              cumulativeQuoteAssetQuantity: binanceReport.cumulativeQuoteAssetTransactedQty,
                                              lastQuoteAssetExecutedQuantity: binanceReport.lastQuoteAssetTransactedQty)
            
            userDataStreamSubscriber?.updated(order: report)
        }
    }
    
}
