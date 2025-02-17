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
import ObjectiveC

private var clientNameKey: UInt8 = 0

extension Telegraph.WebSocket {
    var clientName: String? {
        get {
            return objc_getAssociatedObject(self, &clientNameKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &clientNameKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

class BrowserManager: ObservableObject, ServerWebSocketDelegate {
    
    @Default(.settingsEnableBrowserIntegration) var settingsEnableBrowserIntegration
    @ObservedObject var messageManager: MessageManager
    @Published private var latestMessage: MessageWithParsedOTP?
    @Published var connectedWebSockets: [WebSocket] = []
    private var cancellable: AnyCancellable?
    var server: Server!    
    
    init(messageManager: MessageManager) {
        self.messageManager = messageManager    
                
        cancellable = messageManager.$messages.sink { [weak self] messages in
            guard let self = self else { return }
            
            Logger.core.info("browserManager.messageChanged")
            if let newMessage = messages.last {
                if let latestMessage = self.latestMessage {
                    if newMessage != latestMessage {
                        if self.settingsEnableBrowserIntegration {
                            // Send message to web server
                            sendNotificationToBrowsers(message: newMessage)
                            Task {
                                do {
                                    await messageManager.markMessageAsRead(message: newMessage)
                                } catch {
                                    Logger.core.error("browserManager.error: Failed to mark message as read - \(error)")
                                }
                            }
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
        
        connectedWebSockets.append(webSocket)
        webSocket.clientName = inferClientName(from: handshake)
        Logger.core.info("browserManager.webSocketDidConnect: Client \(webSocket.clientName ?? "Unknown") connected")
        
        let data: [String: Any] = [
            "event": "app.ready",
            "data": []
        ]
        
        sendToSocket(socket: webSocket, data: data)
    }
    
    func server(_ server: Telegraph.Server, webSocketDidDisconnect webSocket: any Telegraph.WebSocket, error: (any Error)?) {
        if let index = connectedWebSockets.firstIndex(where: { $0 === webSocket }) {
            connectedWebSockets.remove(at: index)
        }
        Logger.core.info("browserManager.webSocketDidDisconnect: Client \(webSocket.clientName ?? "Unknown") disconnected")
    }
    
    func server(_ server: Telegraph.Server, webSocket: any Telegraph.WebSocket, didReceiveMessage message: Telegraph.WebSocketMessage) {
        Logger.core.info("browserManager.didReceiveMessage from client \(webSocket.clientName ?? "Unknown")")
    }
    
    func server(_ server: Telegraph.Server, webSocket: any Telegraph.WebSocket, didSendMessage message: Telegraph.WebSocketMessage) {
        Logger.core.info("browserManager.didSendMessage to client \(webSocket.clientName ?? "Unknown")")
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
            connectedWebSockets.removeAll()
            Logger.core.info("browserManager.stopServer.success")
        } else {
            Logger.core.info("browserManager.stopServer.error: No server running to stop")
        }
    }
    
    func sendNotificationToBrowsers(message: MessageWithParsedOTP) {
        Logger.core.info("browserManager.sendNotificationToBrowsers")

        for socket in connectedWebSockets {
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
        Logger.core.info("browserManager.sendToSocket to client \(socket.clientName ?? "Unknown")")
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

    private func inferClientName(from request: Telegraph.HTTPRequest) -> String {
        if let userAgent = request.headers["User-Agent"] {
            if userAgent.contains("Chrome") {
                return "Chrome"
            } else if userAgent.contains("Arc") {
                return "Arc"
            } else if userAgent.contains("Edge") {
                return "Edge"
            } else if userAgent.contains("Brave") {
                return "Brave"
            }
        }
        return "Unknown Browser"
    }

    func getConnectedClientsSummary() -> String {
        let count = connectedWebSockets.count
        if count > 0 {
            let clientNames = connectedWebSockets.compactMap { $0.clientName }.joined(separator: ", ")
            return "\(clientNames) connected"
        } else {
            return ""
        }
    }
}
