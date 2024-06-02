// Wait for the DOM to be fully loaded
console.log('factor.contentscript.loaded');

chrome.runtime.sendMessage({ event: 'factor.content.loaded' });

chrome.runtime.onMessage.addListener(
    function (request, sender, sendResponse) {
        console.log('factor.contentscript.request', request);

        if (request.event == 'code.received') {
            showAutocomplete(request.data);
        }

        if (request.event == 'app.ready') {
            console.log('factor.contentscript.app.ready');
        }
    }
);

function showAutocomplete(data) {
    let code = data.code;

    console.log('factor.contentscript.showAutocomplete', data);

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

        // Insert the div element into the body
        document.body.appendChild(divElement);
    });
}

function onNotificationClicked(code, targetBox, targetInput, e) {
    console.log('factor.contentscript.onNotificationClicked', code);

    targetInput.focus();
    targetInput.value = '';

    document.execCommand('insertText', false, code);

    targetBox.remove();
}