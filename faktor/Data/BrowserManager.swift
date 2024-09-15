//
//  NotificationManager.swift
//  Faktor
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
import OSLog

class BrowserManager: ObservableObject, ServerWebSocketDelegate {
    
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
            
            Logger.core.info("NotificationManager.messageChanged")
            if let newMessage = messages.last {
                if let latestMessage = self.latestMessage {
                    if newMessage != latestMessage {
                        if self.settingsEnableBrowserIntegration {
                            // Send message to web server
                            sendNotificationToBrowsers(message: newMessage)
                            try! messageManager.markMessageAsRead(message: newMessage)
                        }
                    }
                }
            }
            self.latestMessage = messages.last
        }
    }
        
    func server(_ server: Telegraph.Server, webSocketDidConnect webSocket: any Telegraph.WebSocket, handshake: Telegraph.HTTPRequest) {
         Logger.core.info("browserManager.webSocketDidConnect")
         guard handshake.headers["Origin"] == "chrome-extension://lnbhbpdjedbjplopnkkimjenlhneekoc" else {
             Logger.core.error("browserManager.webSocketDidConnect.error: Connection rejected - not from chrome extension")
             return
         }
        
        guard let remoteEndpoint: Telegraph.Endpoint = webSocket.remoteEndpoint else {
            Logger.core.error("browserManager.webSocketDidConnect.error: No remote endpoint")
            return
        }
        
        Logger.core.info("browserManager.webSocketDidConnect")
        let data: [String: Any] = [
            "event": "app.ready",
            "data": []
        ]
        
        sendToSocket(socket: webSocket, data: data)
    }
    
    func server(_ server: Telegraph.Server, webSocketDidDisconnect webSocket: any Telegraph.WebSocket, error: (any Error)?) {
        Logger.core.info("browserManager.webSocketDidDisconnect")
    }
    
    func server(_ server: Telegraph.Server, webSocket: any Telegraph.WebSocket, didReceiveMessage message: Telegraph.WebSocketMessage) {
        Logger.core.info("browserManager.didReceiveMessage")
    }
    
    func server(_ server: Telegraph.Server, webSocket: any Telegraph.WebSocket, didSendMessage message: Telegraph.WebSocketMessage) {
        Logger.core.info("browserManager.didSendMessage")
    }
            
    func startServer() {
        Logger.core.info("browserManager.startServer")
        server = Server()
        server.webSocketDelegate = self
        server.webSocketConfig.pingInterval = 10
        
        do {
            try server.start(port: 9234)
            Logger.core.info("browserManager.startServer.success, port=9234")
        } catch {
            Logger.core.error("browserManager.startServer.error: Failed to start server - \(error.localizedDescription)")
        }
    }

    func stopServer() {
        if let server = server {
            server.stop()
            Logger.core.info("browserManager.stopServer.success")
        } else {
            Logger.core.info("browserManager.stopServer.error: No server running to stop")
        }
    }
    
    func sendNotificationToBrowsers(message:MessageWithParsedOTP) {
        Logger.core.info("browserManager.sendNotificationToBrowsers")

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
        Logger.core.info("browserManager.sendToSocket")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                socket.send(text: jsonString)
                Logger.core.info("browserManager.sendToSocket.success")
            }
        } catch {
            Logger.core.error("browserManager.sendToSocket.error: Failed to encode JSON: \(error.localizedDescription)")
        }
    }

    /// Raised when the web socket client has connected to the server.
//    public func webSocketClient(_ client: WebSocketClient, didConnectToHost host: String) {
//      Logger.core.info("[CLIENT]", "WebSocket connected - host=", host)
//        
//    }

//    /// Raised when the web socket client received data.
//    public func webSocketClient(_ client: WebSocketClient, didReceiveData data: Data) {
//      Logger.core.info("[CLIENT]", "WebSocket message received - data:", data as NSData)
//    }

//    /// Raised when the web socket client received text.
//    public func webSocketClient(_ client: WebSocketClient, didReceiveText text: String) {
//      Logger.core.info("[CLIENT]", "WebSocket message received - text:", text)
//    }

    /// Raised when the web socket client disconnects. Provides an error if the disconnect was unexpected.
//    public func webSocketClient(_ client: WebSocketClient, didDisconnectWithError error: Error?) {
//      Logger.core.info("[CLIENT]", "WebSocket disconnected - error:", error?.localizedDescription ?? "no error")
//    }
//    
    
    //    func serverDidDisconnect(_ server: Telegraph.Server) {
    //        Logger.core.info("serverDidDisconnect")
    //    }
        

}
