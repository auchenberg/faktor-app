// Wait for the DOM to be fully loaded
console.log('factor.contentscript.loaded');

chrome.runtime.sendMessage({ event: 'factor.content.loaded' });


// setTimeout(() => {
//     showAutocomplete({ code: '1234' });
// }, 1000);


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

    // Find all input elements with autocomplete="one-time-code"
    const inputElements = document.querySelectorAll('input');

    console.log('factor.contentscript.showAutocomplete', data, inputElements);

    // Iterate over each input element
    inputElements.forEach(function (inputElement) {

        // Get the position of the input element
        const inputRect = inputElement.getBoundingClientRect();
        // Create a div element
        const divElement = document.createElement('div');
        divElement.classList.add('faktor-notification')

        // Set the position of the div element
        divElement.style.top = `${inputRect.bottom}px`;
        divElement.style.left = `${inputRect.left}px`;

        // Insert the HTML into the DOM
        divElement.innerHTML = `
            <div class="faktor-tooltip">
                <div class="faktor-icon"></div>
                <div class="faktor-content">
                    <p>Fill code ${code}<p>
                    <p class="faktor-source">From Messages</p>
                </div>
            </div>
        `;

        inputElement.onfocus = function () {
            console.log('faktor.contentscript.onfocus', inputElement, divElement)

            setTimeout(() => {
                document.body.appendChild(divElement);
            }, 50);
        }

        inputElement.onblur = function () {
            console.log('faktor.contentscript.onblur', inputElement, divElement)

            setTimeout(() => {
                divElement.remove();
            }, 200);
        }

        divElement.onclick = function onNotificationClicked(e) {
            console.log('factor.contentscript.onClick', code);

            // Fill out value
            inputElement.value = '';
            document.execCommand('insertText', false, code);

            // Clean up
            divElement.remove();
            inputElement.onfocus = null;
            inputElement.onblur = null;
        }

        // Check if inputElement is currently focused
        if (document.activeElement === inputElement) {
            inputElement.onfocus();
        }

    });
}

