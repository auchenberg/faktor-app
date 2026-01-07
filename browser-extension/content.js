// Faktor Content Script
// Uses Shadow DOM for complete style isolation from host page

console.log('faktor.contentscript.loaded');

chrome.runtime.sendMessage({ event: 'factor.content.loaded' });

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
    let notification = new FaktorNotification(id, code, inputElements);
}

// CSS styles to be injected into Shadow DOM
const FAKTOR_STYLES = `
    :host {
        all: initial;
        position: fixed;
        z-index: 2147483647;
        font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
        font-size: 13px;
        line-height: 1.4;
        color-scheme: light dark;
    }

    * {
        box-sizing: border-box;
    }

    .faktor-notification {
        position: relative;
        user-select: none;
        cursor: pointer;
        opacity: 1;
        animation: faktor-fadeIn 100ms ease-in;
    }

    .faktor-tooltip {
        position: relative;
        width: 234px;
        padding: 7px;
        background-color: light-dark(#e4e3e2, #555);
        border: 1px solid light-dark(rgba(255, 255, 255, 0), #838484);
        outline: 0.5px solid light-dark(#b7b7b7, #000);
        color: light-dark(#494949, #efefef);
        box-shadow: 0px 2px 5px rgba(0, 0, 0, 0.2);
        border-radius: 8px;
    }

    .faktor-inner {
        display: flex;
        flex: 1;
        align-items: center;
        padding: 7px;
        border-radius: 8px;
    }

    .faktor-notification:hover .faktor-inner {
        background-color: light-dark(#569fff, #648ee6);
        color: #fff;
    }

    .faktor-content p {
        font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
        font-size: 13px;
        padding: 0 0 1px 0;
        margin: 0;
    }

    .faktor-source {
        font-size: 12px;
        color: light-dark(#656463, #dfe0e1);
    }

    .faktor-notification:hover .faktor-source {
        color: #fff;
    }

    .faktor-icon {
        background: #eee;
        border-radius: 50%;
        width: 24px;
        height: 24px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-right: 10px;
        flex-shrink: 0;
    }

    .faktor-icon::before {
        content: "💬";
        font-size: 14px;
    }

    @keyframes faktor-fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
    }
`;

class FaktorNotification {
    constructor(id, code, inputElements) {
        this.id = id;
        this.code = code;
        this.inputElements = inputElements;
        this.activeInputElement = null;
        this.hostElement = null;
        this.shadowRoot = null;
        this.inputEventController = new AbortController();

        this.init();
    }

    init() {
        console.log('faktor.contentscript.FaktorNotification.init', 'inputs:', this.inputElements.length, 'activeElement:', document.activeElement?.tagName);

        // Create the Shadow DOM host element
        this.createShadowHost();

        this.attachToInputElements();
        this.startAutomaticDisposal();
    }

    createShadowHost() {
        // Create host element for Shadow DOM
        this.hostElement = document.createElement('faktor-notification');
        this.hostElement.style.cssText = 'display: none; position: fixed; z-index: 2147483647;';

        // Attach closed shadow root for maximum isolation
        this.shadowRoot = this.hostElement.attachShadow({ mode: 'closed' });

        // Inject styles into shadow root
        const styleElement = document.createElement('style');
        styleElement.textContent = FAKTOR_STYLES;
        this.shadowRoot.appendChild(styleElement);

        // Add to document
        document.body.appendChild(this.hostElement);
    }

    startAutomaticDisposal() {
        setTimeout(() => this.dispose(), 10000);
    }

    attachToInputElements() {
        this.inputElements.forEach((inputElement) => {
            this.attachInputEventListener(inputElement);
            this.focusInputIfActive(inputElement);
        });
    }

    attachInputEventListener(inputElement) {
        inputElement.addEventListener('focus', this.onInputFocus, { signal: this.inputEventController.signal });
        inputElement.addEventListener('blur', this.onInputBlur, { signal: this.inputEventController.signal });
    }

    detachInputEventListeners() {
        this.inputEventController.abort();
    }

    // Event handlers
    onInputFocus = (e) => {
        let inputElement = e.target;
        // Delay rendering to appear on top of other password managers
        setTimeout(() => this.show(inputElement), 50);
    };

    onInputBlur = (e) => {
        this.hide();
    };

    onNotificationClick = (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.fillValue();
        this.notifyCodeUsed();
        this.dispose();
    };

    notifyCodeUsed() {
        chrome.runtime.sendMessage({
            event: 'code.used',
            data: { id: this.id }
        });
    }

    focusInputIfActive(inputElement) {
        console.log('faktor.contentscript.focusInputIfActive', inputElement, 'isActive:', document.activeElement === inputElement);
        if (document.activeElement === inputElement) {
            inputElement.focus();
            inputElement.dispatchEvent(new Event("focus"));
        }
    }

    fillValue() {
        if (this.activeInputElement) {
            this.activeInputElement.value = '';
            this.activeInputElement.focus();
        }
        document.execCommand('insertText', false, this.code);
    }

    show(inputElement) {
        console.log('faktor.contentscript.FaktorNotification.show', inputElement);

        this.activeInputElement = inputElement;

        // Position the host element
        const inputRect = inputElement.getBoundingClientRect();
        this.hostElement.style.top = `${inputRect.bottom + window.scrollY}px`;
        this.hostElement.style.left = `${inputRect.left + window.scrollX}px`;
        this.hostElement.style.display = 'block';

        // Clear previous content (except styles)
        const existingNotification = this.shadowRoot.querySelector('.faktor-notification');
        if (existingNotification) {
            existingNotification.remove();
        }

        // Create notification content inside shadow root
        const notification = document.createElement('div');
        notification.className = 'faktor-notification';
        notification.innerHTML = `
            <div class="faktor-tooltip">
                <div class="faktor-inner">
                    <div class="faktor-icon"></div>
                    <div class="faktor-content">
                        <p>Fill code ${this.escapeHtml(this.code)}</p>
                        <p class="faktor-source">From Messages</p>
                    </div>
                </div>
            </div>
        `;

        // Use mousedown to prevent blur from firing before click
        notification.addEventListener('mousedown', this.onNotificationClick, true);

        this.shadowRoot.appendChild(notification);
    }

    hide() {
        if (this.hostElement) {
            this.hostElement.style.display = 'none';
        }
        this.activeInputElement = null;

        // Remove notification content but keep styles
        const existingNotification = this.shadowRoot.querySelector('.faktor-notification');
        if (existingNotification) {
            existingNotification.remove();
        }
    }

    dispose() {
        this.hide();
        this.detachInputEventListeners();

        if (this.hostElement && this.hostElement.parentNode) {
            this.hostElement.parentNode.removeChild(this.hostElement);
        }

        this.hostElement = null;
        this.shadowRoot = null;
    }

    // Utility to prevent XSS
    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}
