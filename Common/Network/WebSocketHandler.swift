import Foundation

/// The WebSocketHandler wraps a WebSocket and makes it easier to use
/// close and reconnect the connection to the server.
public class WebSocketHandler {
    
    private let url: URL
    
    var socket: WebSocket?

    var websocketDelegate: WebSocketDelegate? {
        didSet {
            if let socket = self.socket {
                socket.delegate = websocketDelegate
            }
        }
    }
    
    /// Requires the url of the websocket.
    init (url: URL) {
        self.url = url
    }
    
    /// Creates a new WebSocket and calls 'OnCompleted' once the connection
    func createSocket(onCompleted: ((Bool) -> ())? = nil) {
        closeSocket()
        socket = WebSocket(url: url)
        socket?.delegate = websocketDelegate
        socket?.connect()
        socket?.ping() { success in
            onCompleted?(success)
        }
    }
    
    func closeSocket() {
        socket?.delegate = nil
        socket?.disconnect()
    }
}
