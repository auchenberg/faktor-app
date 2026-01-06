# FaktorNativeHost

Native Messaging Host for the Faktor browser extension. This enables more reliable communication between the Faktor macOS app and browser extensions using Chrome's Native Messaging API instead of WebSockets.

## Architecture

```
┌─────────────────┐     stdin/stdout      ┌──────────────────┐
│  Chrome/Arc/    │◄────────────────────►│ FaktorNativeHost │
│  Browser Ext    │   (Native Messaging)  │   (CLI Tool)     │
└─────────────────┘                       └────────┬─────────┘
                                                   │
                                                   │ XPC
                                                   │
                                          ┌────────▼─────────┐
                                          │   Faktor.app     │
                                          │   (Main App)     │
                                          └──────────────────┘
```

## Setup Instructions

### Option 1: Add as Xcode Target (Recommended)

1. **Open the Xcode project**
   ```
   open faktor.xcodeproj
   ```

2. **Add a new target**
   - File → New → Target...
   - Choose "macOS" → "Command Line Tool"
   - Product Name: `FaktorNativeHost`
   - Language: Swift
   - Click "Finish"

3. **Configure the target**
   - Select the FaktorNativeHost target
   - Build Settings:
     - Set `PRODUCT_NAME` to `FaktorNativeHost`
     - Set `MACOSX_DEPLOYMENT_TARGET` to `13.0`
     - Set `SKIP_INSTALL` to `YES`

4. **Add source files**
   - Delete the auto-generated `main.swift`
   - Drag `FaktorNativeHost/main.swift` into the target
   - Ensure it's added to the FaktorNativeHost target only

5. **Add dependency to main app**
   - Select the main "faktor" target
   - Build Phases → Dependencies → Add FaktorNativeHost

6. **Copy native host to app bundle**
   - Select "faktor" target → Build Phases
   - Add "New Copy Files Phase"
   - Destination: "Executables"
   - Add `FaktorNativeHost` product

### Option 2: Build Script Phase

Add this to the main faktor target's Build Phases:

1. Select "faktor" target → Build Phases
2. Click "+" → "New Run Script Phase"
3. Rename to "Build Native Host"
4. Paste this script:

```bash
# Build FaktorNativeHost
NATIVE_HOST_DIR="${SRCROOT}/FaktorNativeHost"
OUTPUT_DIR="${BUILT_PRODUCTS_DIR}"

# Compile native host
swiftc \
    -O \
    -target arm64-apple-macosx13.0 \
    -o "${OUTPUT_DIR}/FaktorNativeHost" \
    "${NATIVE_HOST_DIR}/main.swift"

# Copy to app bundle
cp "${OUTPUT_DIR}/FaktorNativeHost" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/MacOS/"

# Sign the binary
codesign -s "${CODE_SIGN_IDENTITY}" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/Contents/MacOS/FaktorNativeHost"
```

## Native Messaging Manifest

The manifest files need to be installed for each browser. The `NativeMessagingInstaller.swift` handles this automatically, but here's the manual location:

### Chrome
```
~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.faktor.nativehost.json
```

### Arc
```
~/Library/Application Support/Arc/User Data/NativeMessagingHosts/com.faktor.nativehost.json
```

### Brave
```
~/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/com.faktor.nativehost.json
```

### Edge
```
~/Library/Application Support/Microsoft Edge/NativeMessagingHosts/com.faktor.nativehost.json
```

### Manifest Content
```json
{
    "name": "com.faktor.nativehost",
    "description": "Faktor OTP Manager - Native Messaging Host",
    "path": "/Applications/Faktor.app/Contents/MacOS/FaktorNativeHost",
    "type": "stdio",
    "allowed_origins": [
        "chrome-extension://lnbhbpdjedbjplopnkkimjenlhneekoc/"
    ]
}
```

## Browser Extension Changes

The browser extension needs to be updated to use native messaging instead of WebSocket:

```javascript
// Old (WebSocket)
const ws = new WebSocket('ws://localhost:9234');

// New (Native Messaging)
const port = chrome.runtime.connectNative('com.faktor.nativehost');
port.onMessage.addListener((msg) => {
    // Handle messages from app
});
port.postMessage({ event: 'code.used', data: { id: messageId } });
```

## Testing

1. Build and run Faktor.app
2. Open Chrome DevTools on the extension's background page
3. Check for native messaging connection logs
4. Verify the app receives browser connection events

## Troubleshooting

### "Native host has exited"
- Check the manifest path is correct
- Verify FaktorNativeHost is executable
- Check Console.app for crash logs

### "Specified native messaging host not found"
- Manifest file is missing or in wrong location
- Manifest JSON is malformed

### "Access to the specified native messaging host is forbidden"
- Extension ID in manifest doesn't match
- Check `allowed_origins` in manifest
