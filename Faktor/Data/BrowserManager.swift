//
//  BrowserManager.swift
//  Faktor
//
//  Manages browser extension communication via Native Messaging
//  Uses CFMessagePort for IPC with the native messaging host
//

import Foundation
import Combine
import SwiftUI
import Defaults
import OSLog

// MARK: - BrowserManager

/// Manages native messaging communication with browser extensions
/// Uses CFMessagePort for IPC with the native messaging host
class BrowserManager: NSObject, ObservableObject {

    // MARK: - Constants

    /// CFMessagePort name for receiving messages from native host
    private static let messagePortName = "com.faktor.app.messageport"

    // MARK: - Published Properties

    @Published var connectedBrowsers: [ConnectedBrowser] = []

    @Default(.settingsEnableBrowserIntegration) var settingsEnableBrowserIntegration
    @ObservedObject var messageManager: MessageManager

    // MARK: - Private Properties

    private var cancellable: AnyCancellable?
    @Published private var latestMessage: MessageWithParsedOTP?

    // CFMessagePort
    private var messagePort: CFMessagePort?
    private var runLoopSource: CFRunLoopSource?

    // MARK: - Types

    struct ConnectedBrowser: Identifiable, Equatable {
        let id: String
        let name: String
        let connectedAt: Date

        init(id: String = UUID().uuidString, name: String, connectedAt: Date = Date()) {
            self.id = id
            self.name = name
            self.connectedAt = connectedAt
        }
    }

    // MARK: - Initialization

    init(messageManager: MessageManager) {
        self.messageManager = messageManager
        super.init()

        // Observe message changes to send to browsers
        cancellable = messageManager.$messages.sink { [weak self] messages in
            guard let self = self else { return }

            Logger.core.info("BrowserManager: messageChanged")
            if let newMessage = messages.last {
                if let latestMessage = self.latestMessage {
                    if newMessage != latestMessage {
                        if self.settingsEnableBrowserIntegration {
                            self.sendNotificationToBrowsers(message: newMessage)
                        }
                    }
                }
            }
            self.latestMessage = messages.last
        }
    }

    // MARK: - Public Methods

    /// Start the native messaging listener
    func startServer() {
        Logger.core.info("BrowserManager: Starting native messaging listener")

        startMessagePort()

        Logger.core.info("BrowserManager: Native messaging listener started")
    }

    /// Stop the native messaging listener
    func stopServer() {
        Logger.core.info("BrowserManager: Stopping native messaging listener")

        // Stop CFMessagePort
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }

        if let port = messagePort {
            CFMessagePortInvalidate(port)
            messagePort = nil
        }

        DispatchQueue.main.async {
            self.connectedBrowsers.removeAll()
        }

        Logger.core.info("BrowserManager: Native messaging listener stopped")
    }

    /// Send a code notification to all connected browsers
    func sendNotificationToBrowsers(message: MessageWithParsedOTP) {
        let browserCount = connectedBrowsers.count

        Logger.core.info("BrowserManager: Sending notification to browsers (browsers: \(browserCount))")

        if browserCount == 0 {
            Logger.core.warning("BrowserManager: No browsers connected - extension may not have connected yet")
        }

        let eventData: [String: Any] = [
            "id": message.0.guid,
            "code": message.1.code
        ]

        let payload: [String: Any] = [
            "event": "code.received",
            "data": eventData
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload) else {
            Logger.core.error("BrowserManager: Failed to serialize message")
            return
        }

        for browser in connectedBrowsers {
            sendToBrowserViaCFMessagePort(browser: browser, data: jsonData)
        }
    }

    /// Get a summary of connected clients for display
    func getConnectedClientsSummary() -> String {
        let browsers = connectedBrowsers
        if browsers.isEmpty {
            return ""
        }
        return browsers.map { $0.name }.joined(separator: ", ") + " connected"
    }

    // Legacy compatibility
    var connectedWebSockets: [ConnectedBrowser] {
        return connectedBrowsers
    }

    // MARK: - CFMessagePort

    private func startMessagePort() {
        Logger.core.info("BrowserManager: Starting CFMessagePort")

        var context = CFMessagePortContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        messagePort = CFMessagePortCreateLocal(
            nil,
            Self.messagePortName as CFString,
            { (port, msgid, data, info) -> Unmanaged<CFData>? in
                guard let info = info else { return nil }
                let manager = Unmanaged<BrowserManager>.fromOpaque(info).takeUnretainedValue()
                return manager.handleIncomingCFMessage(msgid: msgid, data: data)
            },
            &context,
            nil
        )

        guard let port = messagePort else {
            Logger.core.error("BrowserManager: Failed to create CFMessagePort")
            return
        }

        runLoopSource = CFMessagePortCreateRunLoopSource(nil, port, 0)
        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            Logger.core.info("BrowserManager: CFMessagePort '\(Self.messagePortName)' started")
        }
    }

    /// Send data to a specific browser via CFMessagePort
    private func sendToBrowserViaCFMessagePort(browser: ConnectedBrowser, data: Data) {
        let browserPortName = "com.faktor.nativehost.\(browser.id)"

        guard let remotePort = CFMessagePortCreateRemote(nil, browserPortName as CFString) else {
            Logger.core.warning("BrowserManager: Cannot connect to browser port \(browserPortName)")
            return
        }

        let cfData = data as CFData
        let status = CFMessagePortSendRequest(remotePort, 1, cfData, 5.0, 0, nil, nil)

        if status == kCFMessagePortSuccess {
            Logger.core.info("BrowserManager: Sent message to \(browser.name) via CFMessagePort")
        } else {
            Logger.core.warning("BrowserManager: Failed to send to \(browser.name), status: \(status)")
        }
    }

    // MARK: - CFMessagePort Message Handling

    private func handleIncomingCFMessage(msgid: Int32, data: CFData?) -> Unmanaged<CFData>? {
        guard let data = data as Data? else {
            Logger.core.warning("BrowserManager: Received empty CFMessage")
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let action = json["action"] as? String else {
            Logger.core.warning("BrowserManager: Failed to parse incoming CFMessage")
            return nil
        }

        Logger.core.info("BrowserManager: Received CFMessage action: \(action)")

        switch action {
        case "connect":
            return handleBrowserConnect(json: json)
        case "disconnect":
            return handleBrowserDisconnect(json: json)
        case "message":
            return handleBrowserMessage(json: json)
        case "getState":
            return handleGetState()
        default:
            Logger.core.warning("BrowserManager: Unknown action: \(action)")
            return nil
        }
    }

    private func handleBrowserConnect(json: [String: Any]) -> Unmanaged<CFData>? {
        guard let browserName = json["browserName"] as? String,
              let extensionId = json["extensionId"] as? String,
              let hostId = json["hostId"] as? String else {
            Logger.core.warning("BrowserManager: Missing fields in connect message")
            return nil
        }

        Logger.core.info("BrowserManager: Browser connecting - \(browserName), hostId: \(hostId)")

        let expectedExtensionId = "lnbhbpdjedbjplopnkkimjenlhneekoc"
        guard extensionId == expectedExtensionId else {
            Logger.core.error("BrowserManager: Invalid extension ID: \(extensionId)")
            return createResponse(["success": false, "error": "Invalid extension ID"])
        }

        let browser = ConnectedBrowser(id: hostId, name: browserName)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if !self.connectedBrowsers.contains(where: { $0.id == hostId }) {
                self.connectedBrowsers.append(browser)
                Logger.core.info("BrowserManager: Browser added. Total: \(self.connectedBrowsers.count)")
            }
        }

        return createResponse(["success": true])
    }

    private func handleBrowserDisconnect(json: [String: Any]) -> Unmanaged<CFData>? {
        guard let hostId = json["hostId"] as? String else {
            return nil
        }

        Logger.core.info("BrowserManager: Browser disconnecting - hostId: \(hostId)")

        DispatchQueue.main.async { [weak self] in
            self?.connectedBrowsers.removeAll { $0.id == hostId }
        }

        return createResponse(["success": true])
    }

    private func handleBrowserMessage(json: [String: Any]) -> Unmanaged<CFData>? {
        guard let browserName = json["browserName"] as? String,
              let messageData = json["data"] as? [String: Any] else {
            return nil
        }

        Logger.core.info("BrowserManager: Received message from \(browserName)")

        guard let event = messageData["event"] as? String else {
            Logger.core.warning("BrowserManager: No event in message data")
            return nil
        }

        Logger.core.info("BrowserManager: Event = \(event)")

        if event == "code.used" {
            if let eventData = messageData["data"] as? [String: Any],
               let messageId = eventData["id"] as? String {
                Logger.core.info("BrowserManager: Code used, message id = \(messageId)")

                if let messageToMark = messageManager.messages.first(where: { $0.0.guid == messageId }) {
                    let success = messageManager.markMessageAsRead(message: messageToMark)
                    Logger.core.info("BrowserManager: markMessageAsRead = \(success)")
                } else {
                    Logger.core.warning("BrowserManager: Could not find message with id \(messageId)")
                }
            }
        }

        return createResponse(["success": true])
    }

    private func handleGetState() -> Unmanaged<CFData>? {
        Logger.core.info("BrowserManager: App state requested")

        let state: [String: Any] = [
            "ready": true,
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        ]

        return createResponse(state)
    }

    private func createResponse(_ dict: [String: Any]) -> Unmanaged<CFData>? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        return Unmanaged.passRetained(data as CFData)
    }
}
