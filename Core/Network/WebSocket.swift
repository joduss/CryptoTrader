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
    private var timer: Timer?
    
    public var delegate: WebSocketDelegate?
    public var pingInterval: Double = 120

    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    // MARK: Connection setup
    
    public func connect() {
        sourcePrint("Creating a websocket connection.")
        session?.invalidateAndCancel()
        
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask.resume()
    }
    
    public func disconnect() {
        sourcePrint("Disconnect the websocket.")
        session?.invalidateAndCancel()
        webSocketTask = nil
        session = nil
    }
    
    /// Sends a ping to the server. When the result is back, 'OnCompleted' is called with the result of the ping.
    func ping(onCompleted: ((Bool) -> ())? = nil) {
        webSocketTask?.sendPing { [weak self] error in
            
            guard let strongSelf = self else { return }
            
            if let error = error {
                sourcePrint("Error when sending PING \(error)")
                onCompleted?(false)
                strongSelf.delegate?.error()
                self?.timer?.invalidate()
            } else {
                sourcePrint("Web Socket connection is alive")
                onCompleted?(true)
                DispatchQueue.global().asyncAfter(deadline: .now() + strongSelf.pingInterval) { [weak self] in
                    self?.ping()
                }
            }
        }
    }
    
    private func setupPingTimer() {
        self.timer?.invalidate()
        
        self.timer = Timer(timeInterval: TimeInterval.fromMinutes(2), repeats: true, block: { [weak self] _ in
            self?.ping()
        })
        
        self.timer?.fire()
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
    
    /// Receive a message from the server
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
        setupPingTimer()
        receive()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        sourcePrint("Web socket did close")
        self.timer?.invalidate()
        delegate?.didClose()
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        sourcePrint("URL Session invalid with error \(String(describing: error))")
        self.timer?.invalidate()
        delegate?.error()
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        sourcePrint("Completed with error \(String(describing: error))")
        self.timer?.invalidate()
        delegate?.error()
    }
    
    
}
