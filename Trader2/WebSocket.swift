//
//  WebSocket.swift
//  Trader2
//
//  Created by Jonathan Duss on 10.01.21.
//

import Foundation
import os

// MARK: - Protocols

public protocol WebSocketDelegate {
    func process(response: String)
    func error()
    func didClose()
}

// MARK: - WebSocket
public class WebSocket: NSObject, URLSessionWebSocketDelegate {
    
    
    private let url: URL
    private var webSocketTask: URLSessionWebSocketTask!
    private var session: URLSession!
    
    public var delegate: WebSocketDelegate?

    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    // MARK: Connection setup
    
    public func connect() {
        session?.invalidateAndCancel()
        
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()
    }
    
    public func disconnect() {
        session?.invalidateAndCancel()
        webSocketTask = nil
        session = nil
    }
    
    func ping() {
        webSocketTask?.sendPing { error in
            if let error = error {
                sourcePrint("Error when sending PING \(error)")
                self.delegate?.error()
            } else {
                sourcePrint("Web Socket connection is alive")
                DispatchQueue.global().asyncAfter(deadline: .now() + 10) { [self] in
                    ping()
                }
            }
        }
    }
    
    // MARK : Communication
    
    func send(message: String) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            self.webSocketTask?.send(.string(message)) { error in
                if let error = error {
                    sourcePrint("Error when sending a message: \(error)")
                    self.delegate?.error()
                }
            }
        }
    }
    
    private func receive() {
        webSocketTask?.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .data(_):
                    break
                case .string(let text):
                    self.delegate?.process(response: text)
                default:
                    break
                }
                self.receive()

            case .failure(let error):
                sourcePrint("Error when receiving: \(error)")
                self.delegate?.error()
            }
        }
    }
    
    // MARK: URLSessionDelegate methods
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        sourcePrint("Web Socket did connect")
        ping()
        receive()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        sourcePrint("Web socket did close")
        delegate?.didClose()
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        sourcePrint("URL Session invalid with error \(String(describing: error))")
        delegate?.error()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        sourcePrint("Completed with error \(String(describing: error))")
        delegate?.error()
    }
    
    
}
