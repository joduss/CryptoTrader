import Foundation

protocol ExchangeUserDataStreamSubscriber: AnyObject {
    //func updated(balance: Double)
    func updated(order: OrderExecutionReport)
}

protocol ExchangeUserDataStream: AnyObject {
    var subscribed: Bool { get }
    var webSocketHandler: WebSocketHandler { get }
    var userDataStreamSubscriber: ExchangeUserDataStreamSubscriber? { get set }

    func subscribeUserDataStream()
}

extension ExchangeUserDataStream {
    func resubscribe() {
        if subscribed {
            self.subscribeUserDataStream()
        }
    }
    
    func recreateSocket() {
        webSocketHandler.createSocket { success in
            if success {
                self.resubscribe()
            }
            else {
                sourcePrint("Re-creating the socket failed... trying again in 10 seconds...")
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: { [weak self] in
                    self?.recreateSocket()
                })
            }
        }
    }
    
    public func error() {
        sourcePrint("Websocket connection did encounter an error...")
        recreateSocket()
    }
    
    public func didClose() {
        sourcePrint("Websocket connection did close...")
        recreateSocket()
    }
}
