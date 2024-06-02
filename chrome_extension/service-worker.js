const TEN_SECONDS_MS = 10 * 1000;
let webSocket = null;

chrome.action.onClicked.addListener(async () => {
    if (webSocket) {
        disconnect();
    } else {
        connect();
        keepAlive();
    }
});

function connect() {
    console.log('connecting to websocket');
    webSocket = new WebSocket('ws://localhost:9234');

    webSocket.onopen = () => {
        chrome.action.setIcon({ path: 'icons/socket-active.png' });
    };

    webSocket.onmessage = (event) => {
        let data = JSON.parse(event.data);
        sendNotification(data);
    };

    webSocket.onclose = () => {
        console.log('websocket connection closed');
        webSocket = null;
    };
}

function disconnect() {
    if (webSocket) {
        webSocket.close();
    }
}

function keepAlive() {
    const keepAliveIntervalId = setInterval(
        () => {
            if (webSocket) {
                console.log('ping');
                webSocket.send('ping');
            } else {
                clearInterval(keepAliveIntervalId);
            }
        },
        // It's important to pick an interval that's shorter than 30s, to
        // avoid that the service worker becomes inactive.
        TEN_SECONDS_MS
    );
}

function sendNotification(message) {
    console.log('sending notification', message);
    chrome.tabs.query({}, (tabs) => {
        tabs.forEach((tab) => {
            chrome.tabs.sendMessage(tab.id, { ...message });
        });
    });
}