import Foundation

protocol UserDataStreamSubscriber: class, WebSocketDelegate {
    func updated(balance: Double)
    func updated(order: UserOrderUpdate)
}

protocol UserDataStream: class {
    var subscribed: Bool { get }
    var webSocketHandler: WebSocketHandler { get }

    func subscribe()
}

extension UserDataStream {
    func resubscribe() {
        if subscribed {
            self.subscribe()
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
