// Wait for the DOM to be fully loaded
console.log('content.js loaded');


chrome.runtime.onMessage.addListener(
    function (request, sender, sendResponse) {
        console.log(sender.tab ?
            "from a content script:" + sender.tab.url :
            "from the extension");

        console.log('request', request);

        if (request.event == 'code.received') {
            showAutocomplete(request.data);
        }

        if (request.event == 'app.ready') {
            console.log('got app.ready');
        }
    }
);

function showAutocomplete(data) {
    let code = data.code;

    console.log('showAutocomplete', data);

    // Find all input elements with autocomplete="one-time-code"
    const inputElements = document.querySelectorAll('input[autocomplete="one-time-code"]');

    // Iterate over each input element
    inputElements.forEach(function (inputElement) {

        // Get the position of the input element
        const inputRect = inputElement.getBoundingClientRect();
        // Create a div element
        const divElement = document.createElement('div');
        divElement.classList.add('autho-notification')

        // Set the position of the div element
        divElement.style.top = `${inputRect.bottom}px`;
        divElement.style.left = `${inputRect.left}px`;
        divElement.onclick = onNotificationClicked.bind(this, code, divElement, inputElement);

        // Insert the HTML into the DOM
        divElement.innerHTML = `
            <div class="autho-tooltip">
                <div class="autho-icon"></div>
                <div class="autho-content">
                    <p>Fill code ${code}<p>
                    <p class="autho-source">From Messages</p>
                </div>
            </div>
        `;


        // Insert the div element below the input element
        document.body.appendChild(divElement);
    });
}

function onNotificationClicked(code, targetBox, targetInput, e) {
    console.log('onNotificationClicked', code);

    targetInput.value = code;

    setTimeout(() => {
        targetInput.dispatchEvent(new KeyboardEvent('keydown', { key: code }));
        targetInput.dispatchEvent(new KeyboardEvent('keyup', { key: code }));
        targetInput.dispatchEvent(new KeyboardEvent('input', { key: code }));
    }, 200);

    targetBox.remove();
}

