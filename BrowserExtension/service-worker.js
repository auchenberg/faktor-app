/**
 * Faktor Chrome Extension - Service Worker
 *
 * Uses Chrome Native Messaging to communicate with the Faktor macOS app.
 * This replaces the previous WebSocket implementation for more reliable connectivity.
 */

const NATIVE_HOST_NAME = 'com.faktor.nativehost';
const RECONNECT_DELAY_MS = 2000;
const MAX_RECONNECT_ATTEMPTS = 10;
const PING_INTERVAL_MS = 30000; // 30 seconds

let nativePort = null;
let reconnectAttempts = 0;
let isIntentionalDisconnect = false;
let pingIntervalId = null;
let isConnecting = false;

console.log('faktor.serviceworker.loaded (native messaging)');

// Listen for messages from content scripts
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.event === 'factor.content.loaded') {
        console.log('faktor.serviceworker.onMessage.content.loaded');
        ensureConnection();
    }

    if (request.event === 'code.used') {
        console.log('faktor.serviceworker.onMessage.code.used', request.data);
        sendToApp(request);
    }
});

/**
 * Ensure we have an active connection to the native host
 */
function ensureConnection() {
    if (isConnecting) {
        console.log('faktor.serviceworker.ensureConnection: Connection already in progress');
        return;
    }

    if (!nativePort) {
        connect();
    }
}

/**
 * Connect to the native messaging host
 */
function connect() {
    if (isConnecting) {
        return;
    }

    isConnecting = true;
    console.log('faktor.serviceworker.connect: Connecting to native host...');

    try {
        nativePort = chrome.runtime.connectNative(NATIVE_HOST_NAME);

        nativePort.onMessage.addListener(handleMessage);
        nativePort.onDisconnect.addListener(handleDisconnect);

        // Connection successful
        console.log('faktor.serviceworker.connected: Native messaging port opened');
        reconnectAttempts = 0;
        isIntentionalDisconnect = false;
        isConnecting = false;

        // Start ping interval to keep service worker alive
        startPingInterval();

    } catch (error) {
        console.error('faktor.serviceworker.connect: Error connecting to native host', error);
        isConnecting = false;
        nativePort = null;
        attemptReconnect();
    }
}

/**
 * Handle incoming messages from the native host
 */
function handleMessage(message) {
    console.log('faktor.serviceworker.onMessage:', message);

    try {
        // The message is already parsed JSON from native messaging
        const { event, data } = message;

        switch (event) {
            case 'app.ready':
                console.log('faktor.serviceworker.app.ready');
                // Notify all tabs that the app is ready
                sendNotificationToTabs({ event: 'app.ready', data: {} });
                break;

            case 'app.disconnected':
                console.log('faktor.serviceworker.app.disconnected:', data?.reason);
                // The native host lost connection to the Faktor app
                // It will auto-reconnect, just log for now
                break;

            case 'code.received':
                console.log('faktor.serviceworker.code.received:', data);
                // Forward to all content scripts
                sendNotificationToTabs({ event: 'code.received', data });
                break;

            case 'code.used.ack':
                console.log('faktor.serviceworker.code.used.ack');
                break;

            case 'pong':
                console.log('faktor.serviceworker.pong');
                break;

            default:
                console.log('faktor.serviceworker.unknown.event:', event);
                // Forward unknown events to tabs anyway
                sendNotificationToTabs(message);
        }
    } catch (error) {
        console.error('faktor.serviceworker.onMessage: Error handling message', error);
    }
}

/**
 * Handle disconnection from native host
 */
function handleDisconnect() {
    const error = chrome.runtime.lastError;
    console.log('faktor.serviceworker.disconnected:', error?.message || 'Unknown reason');

    nativePort = null;
    stopPingInterval();

    if (!isIntentionalDisconnect) {
        // Notify tabs about connection failure if max attempts reached
        if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
            notifyUserOfConnectionFailure(error?.message);
        }
        attemptReconnect();
    }
}

/**
 * Attempt to reconnect with exponential backoff
 */
function attemptReconnect() {
    if (reconnectAttempts >= MAX_RECONNECT_ATTEMPTS) {
        console.log('faktor.serviceworker.reconnect: Max attempts reached');
        return;
    }

    reconnectAttempts++;
    const delay = RECONNECT_DELAY_MS * Math.pow(1.5, reconnectAttempts - 1);

    console.log(`faktor.serviceworker.reconnect: Attempt ${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS} in ${Math.round(delay)}ms`);

    setTimeout(() => {
        if (!nativePort && !isIntentionalDisconnect) {
            connect();
        }
    }, delay);
}

/**
 * Notify content scripts about connection failure
 */
function notifyUserOfConnectionFailure(errorMessage) {
    console.log('faktor.serviceworker.notifyUserOfConnectionFailure');

    let userMessage = 'Unable to connect to Faktor app. ';

    if (errorMessage?.includes('not found')) {
        userMessage += 'Please make sure Faktor is installed and running.';
    } else if (errorMessage?.includes('forbidden')) {
        userMessage += 'Native messaging is not configured. Please open Faktor app to set it up.';
    } else {
        userMessage += 'Please make sure Faktor is running.';
    }

    sendNotificationToTabs({
        event: 'factor.connection.failed',
        message: userMessage
    });
}

/**
 * Intentionally disconnect from native host
 */
function disconnect() {
    console.log('faktor.serviceworker.disconnect');
    isIntentionalDisconnect = true;
    stopPingInterval();

    if (nativePort) {
        nativePort.disconnect();
        nativePort = null;
    }
}

/**
 * Start ping interval to keep service worker and connection alive
 */
function startPingInterval() {
    if (pingIntervalId) {
        return;
    }

    console.log('faktor.serviceworker.startPingInterval');

    pingIntervalId = setInterval(() => {
        if (nativePort) {
            console.log('faktor.serviceworker.ping');
            try {
                nativePort.postMessage({ event: 'ping' });
            } catch (error) {
                console.error('faktor.serviceworker.ping: Error sending ping', error);
                stopPingInterval();
            }
        } else {
            stopPingInterval();
            if (!isIntentionalDisconnect) {
                ensureConnection();
            }
        }
    }, PING_INTERVAL_MS);
}

/**
 * Stop the ping interval
 */
function stopPingInterval() {
    if (pingIntervalId) {
        clearInterval(pingIntervalId);
        pingIntervalId = null;
    }
}

/**
 * Send notification to all tabs
 */
function sendNotificationToTabs(message) {
    console.log('faktor.serviceworker.sendNotificationToTabs:', message.event);

    chrome.tabs.query({}, (tabs) => {
        console.log('faktor.serviceworker.sendNotificationToTabs: found', tabs.length, 'tabs');
        tabs.forEach((tab) => {
            // Only send to tabs with URLs (skip chrome:// pages, etc.)
            if (tab.id && tab.url && !tab.url.startsWith('chrome://')) {
                console.log('faktor.serviceworker.sendToTab:', tab.id, tab.url?.substring(0, 50));
                chrome.tabs.sendMessage(tab.id, message)
                    .then(() => {
                        console.log('faktor.serviceworker.sendToTab.success:', tab.id);
                    })
                    .catch((err) => {
                        console.log('faktor.serviceworker.sendToTab.error:', tab.id, err.message);
                    });
            }
        });
    });
}

/**
 * Send message to the native app
 */
function sendToApp(message) {
    console.log('faktor.serviceworker.sendToApp:', message);

    if (nativePort) {
        try {
            nativePort.postMessage(message);
        } catch (error) {
            console.error('faktor.serviceworker.sendToApp: Error sending message', error);
        }
    } else {
        console.warn('faktor.serviceworker.sendToApp: Not connected to native host');
        // Try to reconnect
        ensureConnection();
    }
}

// Initialize connection when service worker starts
ensureConnection();
