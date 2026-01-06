//
//  main.swift
//  FaktorNativeHost
//
//  Native Messaging Host for Chrome extension communication
//  Uses CFMessagePort for IPC with the main Faktor app
//

import Foundation
import AppKit

// MARK: - Constants

enum Constants {
    static let extensionId = "afhmgkpdmifnmflcaegmjcaaehfklepp"
    static let appPortName = "com.faktor.app.messageport"
    static let appURLScheme = "faktor://activate"
    static let appBundleId = "com.faktor.app"
    static let reconnectInterval: TimeInterval = 2.0
    static let maxReconnectAttempts = 60  // 2 minutes of retrying (app might need time to launch)
}

// MARK: - Logging

func log(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let logMessage = "[\(timestamp)] FaktorNativeHost: \(message)\n"

    // Log to stderr (doesn't interfere with native messaging on stdout)
    FileHandle.standardError.write(logMessage.data(using: .utf8) ?? Data())

    // Also log to file for debugging
    let logDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        .appendingPathComponent("Faktor/Logs")
    try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)

    let logFile = logDir.appendingPathComponent("nativehost.log")
    if let handle = try? FileHandle(forWritingTo: logFile) {
        handle.seekToEndOfFile()
        handle.write(logMessage.data(using: .utf8) ?? Data())
        handle.closeFile()
    } else {
        try? logMessage.data(using: .utf8)?.write(to: logFile)
    }
}

// MARK: - Native Messaging Protocol (Chrome <-> Native Host)

/// Read a message from stdin (from Chrome extension)
func readMessage() -> [String: Any]? {
    let stdin = FileHandle.standardInput

    // Read 4-byte length header
    let lengthData = stdin.readData(ofLength: 4)
    guard lengthData.count == 4 else {
        log("Failed to read message length (got \(lengthData.count) bytes)")
        return nil
    }

    let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self) }

    guard length > 0 && length < 1024 * 1024 else {
        log("Invalid message length: \(length)")
        return nil
    }

    // Read message body
    let messageData = stdin.readData(ofLength: Int(length))
    guard messageData.count == length else {
        log("Failed to read message body (expected \(length), got \(messageData.count))")
        return nil
    }

    guard let json = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any] else {
        log("Failed to parse message as JSON")
        return nil
    }

    return json
}

/// Send a message to stdout (to Chrome extension)
func sendMessageToChrome(_ message: [String: Any]) {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
        log("Failed to serialize message to JSON")
        return
    }

    // Create 4-byte length header (native byte order)
    var messageLength = UInt32(jsonData.count)
    let lengthData = withUnsafeBytes(of: &messageLength) { Data($0) }

    // Write length + message to stdout
    let stdout = FileHandle.standardOutput
    stdout.write(lengthData)
    stdout.write(jsonData)

    log("Sent to Chrome: \(jsonString)")
}

// MARK: - CFMessagePort Communication with Main App

class AppConnection {
    private var remotePort: CFMessagePort?
    private var localPort: CFMessagePort?
    private var runLoopSource: CFRunLoopSource?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private var isConnected = false

    let hostId: String
    var browserName: String = "Unknown"

    init() {
        hostId = UUID().uuidString
    }

    func connect() -> Bool {
        log("Attempting to connect to Faktor app via CFMessagePort")
        log("Looking for port: \(Constants.appPortName)")

        // Connect to the app's message port
        remotePort = CFMessagePortCreateRemote(nil, Constants.appPortName as CFString)

        guard remotePort != nil else {
            log("Failed to connect to app message port - is Faktor app running?")
            isConnected = false
            return false
        }

        log("Successfully connected to Faktor app")
        isConnected = true
        reconnectAttempts = 0

        // Create local port for receiving messages from the app
        setupLocalPort()

        return true
    }

    private func setupLocalPort() {
        // Clean up existing local port if any
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
            runLoopSource = nil
        }
        if let port = localPort {
            CFMessagePortInvalidate(port)
            localPort = nil
        }

        let localPortName = "com.faktor.nativehost.\(hostId)"
        var context = CFMessagePortContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        localPort = CFMessagePortCreateLocal(
            nil,
            localPortName as CFString,
            { (port, msgid, data, info) -> Unmanaged<CFData>? in
                guard let info = info,
                      let data = data as Data? else { return nil }
                let connection = Unmanaged<AppConnection>.fromOpaque(info).takeUnretainedValue()
                connection.handleMessageFromApp(data)
                return nil
            },
            &context,
            nil
        )

        if let port = localPort {
            runLoopSource = CFMessagePortCreateRunLoopSource(nil, port, 0)
            if let source = runLoopSource {
                CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
                log("Local port '\(localPortName)' created for receiving messages")
            }
        }
    }

    func startReconnectTimer() {
        // Don't start if already reconnecting
        guard reconnectTimer == nil else { return }

        log("Starting reconnect timer")
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: Constants.reconnectInterval, repeats: true) { [weak self] _ in
            self?.attemptReconnect()
        }
    }

    func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    private func attemptReconnect() {
        reconnectAttempts += 1
        log("Reconnect attempt \(reconnectAttempts)/\(Constants.maxReconnectAttempts)")

        if reconnectAttempts > Constants.maxReconnectAttempts {
            log("Max reconnect attempts reached, giving up")
            stopReconnectTimer()

            // Notify Chrome that we couldn't reconnect
            let errorMessage: [String: Any] = [
                "event": "app.disconnected",
                "data": ["reason": "Max reconnect attempts reached"]
            ]
            sendMessageToChrome(errorMessage)
            return
        }

        // Try to launch Faktor if not running (on first few attempts)
        if reconnectAttempts == 1 || reconnectAttempts == 5 {
            launchFaktorAppIfNeeded()
        }

        // Try to reconnect
        remotePort = CFMessagePortCreateRemote(nil, Constants.appPortName as CFString)

        if remotePort != nil {
            log("Reconnected to Faktor app!")
            isConnected = true
            reconnectAttempts = 0
            stopReconnectTimer()

            // Re-register with the app
            notifyBrowserConnected(browserName: browserName)

            // Notify Chrome that we're connected again
            let readyMessage: [String: Any] = [
                "event": "app.ready",
                "data": [] as [Any]
            ]
            sendMessageToChrome(readyMessage)
        }
    }

    /// Launch the Faktor app if it's not already running
    private func launchFaktorAppIfNeeded() {
        // Check if Faktor is already running
        let runningApps = NSWorkspace.shared.runningApplications
        let faktorRunning = runningApps.contains { $0.bundleIdentifier == Constants.appBundleId }

        if faktorRunning {
            log("Faktor app is already running")
            return
        }

        log("Faktor app not running, attempting to launch...")

        // Try URL scheme first
        if let url = URL(string: Constants.appURLScheme) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false  // Don't bring to front

            NSWorkspace.shared.open(url, configuration: config) { app, error in
                if let error = error {
                    log("Failed to launch via URL scheme: \(error.localizedDescription)")
                    // Fallback: try to launch by bundle ID
                    self.launchFaktorByBundleId()
                } else {
                    log("Faktor launched via URL scheme")
                }
            }
        } else {
            launchFaktorByBundleId()
        }
    }

    private func launchFaktorByBundleId() {
        log("Attempting to launch Faktor by bundle ID...")

        let config = NSWorkspace.OpenConfiguration()
        config.activates = false

        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Constants.appBundleId) {
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
                if let error = error {
                    log("Failed to launch Faktor: \(error.localizedDescription)")
                } else {
                    log("Faktor launched successfully")
                }
            }
        } else {
            log("Could not find Faktor app by bundle ID")

            // Last resort: try to open from /Applications
            let appPath = "/Applications/Faktor.app"
            if FileManager.default.fileExists(atPath: appPath) {
                let appURL = URL(fileURLWithPath: appPath)
                NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
                    if let error = error {
                        log("Failed to launch Faktor from /Applications: \(error.localizedDescription)")
                    } else {
                        log("Faktor launched from /Applications")
                    }
                }
            }
        }
    }

    func notifyBrowserConnected(browserName: String) {
        self.browserName = browserName

        let message: [String: Any] = [
            "action": "connect",
            "browserName": browserName,
            "extensionId": Constants.extensionId,
            "hostId": hostId
        ]

        sendToApp(message)
    }

    func notifyBrowserDisconnected() {
        let message: [String: Any] = [
            "action": "disconnect",
            "hostId": hostId
        ]

        sendToApp(message)
    }

    func sendBrowserMessage(_ data: [String: Any]) {
        let message: [String: Any] = [
            "action": "message",
            "browserName": browserName,
            "hostId": hostId,
            "data": data
        ]

        sendToApp(message)
    }

    private func sendToApp(_ message: [String: Any]) {
        guard let port = remotePort else {
            log("Cannot send to app - not connected")
            handleDisconnection()
            return
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: message) else {
            log("Failed to serialize message for app")
            return
        }

        var returnData: Unmanaged<CFData>?
        let status = CFMessagePortSendRequest(
            port,
            0,
            jsonData as CFData,
            5.0,  // send timeout
            5.0,  // receive timeout
            CFRunLoopMode.defaultMode.rawValue,
            &returnData
        )

        if status == kCFMessagePortSuccess {
            log("Message sent to app successfully")
            if let data = returnData?.takeRetainedValue() as Data?,
               let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                log("App response: \(response)")
            }
        } else {
            log("Failed to send message to app, status: \(status)")
            // Status codes: kCFMessagePortSendTimeout = -1, kCFMessagePortReceiveTimeout = -2,
            // kCFMessagePortIsInvalid = -3, kCFMessagePortTransportError = -4
            if status == -3 || status == -4 {
                handleDisconnection()
            }
        }
    }

    private func handleDisconnection() {
        guard isConnected else { return }  // Already handling disconnection

        log("App connection lost, starting reconnection...")
        isConnected = false
        remotePort = nil

        // Notify Chrome about disconnection
        let disconnectMessage: [String: Any] = [
            "event": "app.disconnected",
            "data": ["reason": "Connection lost, reconnecting..."]
        ]
        sendMessageToChrome(disconnectMessage)

        // Start reconnection attempts
        startReconnectTimer()
    }

    private func handleMessageFromApp(_ data: Data) {
        log("Received message from app: \(data.count) bytes")

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            log("Failed to parse message from app")
            return
        }

        // Forward to Chrome extension
        sendMessageToChrome(json)
    }

    func cleanup() {
        stopReconnectTimer()
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        }
        if let port = localPort {
            CFMessagePortInvalidate(port)
        }
        notifyBrowserDisconnected()
    }

    /// Check if still connected to app (called periodically)
    func checkConnection() {
        guard isConnected, let port = remotePort else {
            if !isConnected && reconnectTimer == nil {
                startReconnectTimer()
            }
            return
        }

        // Try a simple ping to verify connection is still alive
        if !CFMessagePortIsValid(port) {
            log("Remote port is no longer valid")
            handleDisconnection()
        }
    }
}

// MARK: - Main

log("FaktorNativeHost starting")
log("Process ID: \(ProcessInfo.processInfo.processIdentifier)")
log("Arguments: \(CommandLine.arguments)")

// Detect browser from Chrome's native messaging origin
var browserName = "Chrome"
if CommandLine.arguments.count > 1 {
    let origin = CommandLine.arguments[1]
    log("Origin: \(origin)")

    if origin.contains("chrome-extension://\(Constants.extensionId)") {
        // Could detect Arc, Brave, Edge by checking process tree, but default to Chrome
        browserName = "Chrome"
    }
}

// Connect to main app
let appConnection = AppConnection()
var initialConnectionSucceeded = false

if appConnection.connect() {
    appConnection.notifyBrowserConnected(browserName: browserName)
    initialConnectionSucceeded = true
} else {
    // App not running yet, start trying to connect
    log("Initial connection failed, will retry...")
    appConnection.startReconnectTimer()
}

// Send initial app.ready message to the extension (or app.disconnected if not connected)
if initialConnectionSucceeded {
    let readyMessage: [String: Any] = [
        "event": "app.ready",
        "data": [] as [Any]
    ]
    sendMessageToChrome(readyMessage)
} else {
    let waitingMessage: [String: Any] = [
        "event": "app.disconnected",
        "data": ["reason": "Waiting for Faktor app to start..."]
    ]
    sendMessageToChrome(waitingMessage)
}

// Main message loop - read from Chrome, forward to app
log("Entering message loop")

// Set up a timer to process the run loop and check connection
let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
    // Run loop iteration to process messages from app
}
RunLoop.current.add(timer, forMode: .default)

// Connection health check timer (every 5 seconds)
let healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
    appConnection.checkConnection()
}
RunLoop.current.add(healthCheckTimer, forMode: .default)

// Process stdin in a background thread
DispatchQueue.global(qos: .userInteractive).async {
    while true {
        guard let message = readMessage() else {
            log("No more messages from Chrome, exiting")
            break
        }

        if let event = message["event"] as? String {
            log("Received event from Chrome: \(event)")

            switch event {
            case "code.used":
                // Forward to main app
                appConnection.sendBrowserMessage(message)

                // Send acknowledgment to browser
                let ack: [String: Any] = [
                    "event": "code.used.ack",
                    "data": ["success": true]
                ]
                sendMessageToChrome(ack)

            case "ping":
                // Respond to ping
                let pong: [String: Any] = [
                    "event": "pong",
                    "data": ["timestamp": ISO8601DateFormatter().string(from: Date())]
                ]
                sendMessageToChrome(pong)

            default:
                log("Unknown event: \(event)")
            }
        }
    }

    // Cleanup and exit
    timer.invalidate()
    healthCheckTimer.invalidate()
    appConnection.cleanup()
    log("FaktorNativeHost exiting")
    exit(0)
}

// Run the main run loop
RunLoop.current.run()
