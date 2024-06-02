const TEN_SECONDS_MS = 10 * 1000;
let webSocket = null;
let keepAliveIntervalId = null;

console.log('factor.serviceworker.loaded');

chrome.runtime.onMessage.addListener(
    function (request, sender, sendResponse) {
        if (request.event == 'factor.content.loaded') {
            if (!webSocket) {
                connect();
            }
            keepAlive();
        }
    }
);

function connect() {
    console.log('factor.serviceworker.connect');
    webSocket = new WebSocket('ws://localhost:9234');

    webSocket.onmessage = (event) => {
        let data = JSON.parse(event.data);
        sendNotification(data);
    };

    webSocket.onclose = () => {
        console.log('factor.serviceworker.closed');
        webSocket = null;
    };
}

function disconnect() {
    if (webSocket) {
        webSocket.close();
    }
}

function keepAlive() {

    if (keepAliveIntervalId) {
        return;
    }

    keepAliveIntervalId = setInterval(
        () => {
            if (webSocket) {
                console.log('ping');
                webSocket.send('ping');
            } else {
                clearInterval(keepAliveIntervalId);
                keepAliveIntervalId = null;
            }
        },
        // It's important to pick an interval that's shorter than 30s, to
        // avoid that the service worker becomes inactive.
        TEN_SECONDS_MS
    );
}

function sendNotification(message) {
    console.log('factor.serviceworker.sendNotification');
    chrome.tabs.query({}, (tabs) => {
        tabs.forEach((tab) => {
            chrome.tabs.sendMessage(tab.id, { ...message });
        });
    });
}