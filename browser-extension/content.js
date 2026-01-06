// Wait for the DOM to be fully loaded
console.log('faktor.contentscript.loaded');

chrome.runtime.sendMessage({ event: 'factor.content.loaded' });

// Useful for testing
// setTimeout(() => {
//     showAutocomplete({ code: '1234' });
// }, 1000);

chrome.runtime.onMessage.addListener(
    function (request, sender, sendResponse) {
        console.log('faktor.contentscript.onMessage', request);

        if (request.event == 'code.received') {
            console.log('faktor.contentscript.code.received', request.data);
            showAutocomplete(request.data);
        }

        if (request.event == 'app.ready') {
            console.log('faktor.contentscript.app.ready');
        }
    }
);

function showAutocomplete(data) {
    const code = data.code;
    const id = data.id;
    const inputElements = document.querySelectorAll('input');

    console.log('faktor.contentscript.showAutocomplete', data, 'inputs:', inputElements.length);
    let notification = new Notification(id, code, inputElements);
}

class Notification {
    constructor(id, code, inputElements) {
        this.id = id;
        this.code = code;
        this.inputElements = inputElements;
        this.activeInputElement = null;
        this.divNotification = document.createElement('div');
        this.inputEventController = new AbortController();

        // Initialize the notification
        this.init();
    }

    init() {
        console.log('faktor.contentscript.Notification.init', 'inputs:', this.inputElements.length, 'activeElement:', document.activeElement?.tagName);
        this.divNotification.classList.add('faktor-notification');
        this.attachToInputElements();
        this.attachNotificationEventListeners();
        this.startAutomaticDisposal();
    }

    startAutomaticDisposal() {
        // console.log('factor.contentscript.startAutomaticDisposal');
        setTimeout(this.dispose, 10000);
    }

    attachToInputElements() {
        this.inputElements.forEach((inputElement) => {
            this.attachInputEventListener(inputElement);

            // Check if inputElement is currently focused
            this.focusInputIfActive(inputElement);

        });
    }

    attachInputEventListener(inputElement) {
        // console.log('factor.contentscript.attachInputEventListener', inputElement)
        inputElement.addEventListener('focus', this.onInputFocus, { signal: this.inputEventController.signal });
        inputElement.addEventListener('blur', this.onInputBlur, { signal: this.inputEventController.signal });
    }

    detachInputEventListeners() {
        // console.log('factor.contentscript.detachInputEventListeners')

        // use abort controller to scope issues, https://macarthur.me/posts/options-for-removing-event-listeners/
        this.inputEventController.abort();
    }

    attachNotificationEventListeners() {
        // console.log('factor.contentscript.attachNotificationEventListeners', this.divNotification)
        // Use onmousedown instead of onclick to prevent the blur event from firing. See https://stackoverflow.com/questions/17769005/onclick-and-onblur-ordering-issue
        this.divNotification.addEventListener('mousedown', this.onNotificationClick, true);
    }

    detachNotificationEventListeners() {
        // console.log('factor.contentscript.detachNotificationEventListeners', this.divNotification)
        this.divNotification.removeEventListener('mousedown', this.onNotificationClick);
    }

    // Event handlers
    onInputFocus = (e) => {
        let inputElement = e.target;
        // console.log('faktor.contentscript.focus', inputElement, this.divNotification);

        // Delay rendering to make the notification is appearing on top of 1password or other password managers
        setTimeout(this.show.bind(this, inputElement), 50);
    };

    onInputBlur = (e) => {
        let inputElement = e.target;
        // console.log('faktor.contentscript.blur', inputElement, this.divNotification);
        this.remove();
    };

    onNotificationClick = (e) => {
        // console.log('factor.contentscript.click', this.code);
        this.fillValue();
        this.notifyCodeUsed();
        this.dispose();
    };

    notifyCodeUsed() {
        // console.log('factor.contentscript.notifyCodeUsed', this.id);
        chrome.runtime.sendMessage({
            event: 'code.used',
            data: { id: this.id }
        });
    }

    // Utils
    focusInputIfActive(inputElement) {
        console.log('faktor.contentscript.focusInputIfActive', inputElement, 'isActive:', document.activeElement === inputElement);
        if (document.activeElement === inputElement) {
            inputElement.focus();
            inputElement.dispatchEvent(new Event("focus"));
        }
    }

    fillValue() {
        // console.log('factor.contentscript.fillValue');

        // Clear existing value
        if (this.activeInputElement) {
            this.activeInputElement.value = '';
        }

        // Fill out value
        document.execCommand('insertText', false, this.code);
    }

    // Core methods
    show(inputElement) {
        console.log('faktor.contentscript.Notification.show', inputElement);

        // Set the active input element
        this.activeInputElement = inputElement;

        // Set the position of the div element
        const inputRect = inputElement.getBoundingClientRect();
        this.divNotification.style.top = `${inputRect.bottom}px`;
        this.divNotification.style.left = `${inputRect.left}px`;

        // Insert the HTML into the DOM
        this.divNotification.innerHTML = `
            <div class="faktor-tooltip">
                <div class="faktor-inner">
                    <div class="faktor-icon"></div>
                    <div class="faktor-content">
                        <p>Fill code ${this.code}</p>
                        <p class="faktor-source">From Messages</p>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(this.divNotification);
    }

    remove() {
        // console.log('factor.contentscript.remove', this.divNotification);
        this.detachNotificationEventListeners();

        // Clear the active input element
        this.activeInputElement = null;

        if (this.divNotification) {
            this.divNotification.remove();
        }
    }

    dispose = () => {
        // console.log('factor.contentscript.dispose', this.inputElements, this.divNotification);
        this.remove();
        this.detachInputEventListeners();
    };
}