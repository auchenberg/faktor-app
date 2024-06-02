//
//  NotificationManager.swift
//  autho
//
//  Created by Kenneth Auchenberg on 5/25/24.
//

import Foundation
import ServiceManagement
import Combine
import SwiftUI
import Defaults
import UserNotifications
import Telegraph

class BrowserManager: ServerWebSocketDelegate {
    
    /// Raised when the web socket client has connected to the server.
    public func webSocketClient(_ client: WebSocketClient, didConnectToHost host: String) {
      print("[CLIENT]", "WebSocket connected - host:", host)
    }

    /// Raised when the web socket client received data.
    public func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data) {
      print("[CLIENT]", "WebSocket message received - data:", data as NSData)
    }

    /// Raised when the web socket client received text.
    public func webSocketClient(_ client: WebSocketClient, didReceiveText text: String) {
      print("[CLIENT]", "WebSocket message received - text:", text)
    }

    /// Raised when the web socket client disconnects. Provides an error if the disconnect was unexpected.
    public func webSocketClient(_ client: WebSocketClient, didDisconnectWithError error: Error?) {
      print("[CLIENT]", "WebSocket disconnected - error:", error?.localizedDescription ?? "no error")
    }
    
    
    func server(_ server: Telegraph.Server, webSocketDidConnect webSocket: any Telegraph.WebSocket, handshake: Telegraph.HTTPRequest) {
        print("webSocketDidConnect", handshake, webSocket)
        let data: [String: Any] = [
            "event": "app.ready",
            "data": []
        ]
        
        sendToSocket(socket: webSocket, data: data)
    }
    
    func server(_ server: Telegraph.Server, webSocketDidDisconnect webSocket: any Telegraph.WebSocket, error: (any Error)?) {
        print("webSocketDidDisconnect")
    }
    
    func server(_ server: Telegraph.Server, webSocket: any Telegraph.WebSocket, didReceiveMessage message: Telegraph.WebSocketMessage) {
        print("didReceiveMessage")
    }
    
    func server(_ server: Telegraph.Server, webSocket: any Telegraph.WebSocket, didSendMessage message: Telegraph.WebSocketMessage) {
        print("didSendMessage")
    }
    
    func serverDidDisconnect(_ server: Telegraph.Server) {
        print("serverDidDisconnect")
    }
    
    @Default(.settingsEnableBrowserIntegration) var settingsEnableBrowserIntegration
    @ObservedObject var messageManager: MessageManager
    @Published private var latestMessage: MessageWithParsedOTP?
    private var cancellable: AnyCancellable?
    
    var server: Server!
    
    init(messageManager: MessageManager) {
        self.messageManager = messageManager
                
        cancellable = messageManager.$messages.sink { [weak self] messages in
            guard let self = self else {
                return
            }
            
            print("NotificationManager.messageChanged")
            if let newMessage = messages.last {
                if let latestMessage = self.latestMessage {
                    if newMessage != latestMessage {
                        if self.settingsEnableBrowserIntegration {
                            // Send message to web server
                            sendNotificationToBrowsers(message:newMessage)
                        }
                    }
                }
            }
            self.latestMessage = messages.last
        }
    }
    
    func startServer() {
        
        server = Server()
        server.webSocketDelegate = self
        server.webSocketConfig.pingInterval = 10
        
        try! server.start(port: 9234)
        
        print("[SERVER]", "Server is running - url:")
    }
    
    func sendNotificationToBrowsers(message:MessageWithParsedOTP) {
        print("sendNotificationToBrowsers", message)

        for socket in server.webSockets {
            
            
            let data: [String: Any] = [
                "event": "code.received",
                "data": [
                    "code": message.1.code
                ]
            ]
            
            sendToSocket(socket: socket, data: data)
        }
        
    }
    
    func sendToSocket(socket: WebSocket, data: Any) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                socket.send(text: jsonString)
                
            }
        } catch {
            print("Failed to encode JSON: \(error.localizedDescription)")
        }
    
    }

}


