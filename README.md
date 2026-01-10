# Faktor

Faktor is a Mac app that keeps an eye out for new 2FA codes and gives you a great autocomplete experience in Google Chrome.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Automatic OTP Detection** - Monitors incoming SMS messages and extracts verification codes
- **Browser Autofill** - Seamlessly fills OTP codes in Chrome, Arc, Brave, and Edge via browser extension
- **100+ Services Supported** - Built-in parsers for Google, Apple, Amazon, Microsoft, and many more
- **Privacy Focused** - All data stays on your Mac, no cloud sync required
- **Menu Bar App** - Minimal footprint, runs quietly in your menu bar

## How It Works

```
┌─────────────────┐                    ┌──────────────────┐
│   Messages.app  │───────────────────►│   Faktor.app     │
│   (iMessage)    │   Reads Messages   │   (Menu Bar)     │
└─────────────────┘                    └────────┬─────────┘
                                                │
                                                │ Native Messaging
                                                ▼
                                       ┌──────────────────┐
                                       │ Browser Extension│
                                       │ (Chrome/Arc/etc) │
                                       └──────────────────┘
```

1. **Faktor** reads your Messages database (requires Full Disk Access permission)
2. Incoming SMS messages are parsed for OTP codes using regex patterns
3. Detected codes are sent to the browser extension via Chrome Native Messaging
4. The extension displays an autofill UI on login pages

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+ (for building from source)
- Chrome, Arc, Brave, or Microsoft Edge browser

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/user/faktor-app.git
   cd faktor-app
   ```

2. Open the Xcode project:
   ```bash
   open faktor.xcodeproj
   ```

3. Build and run (⌘R)

4. Grant required permissions when prompted:
   - **Full Disk Access** - Required to read the Messages database
   - **Notifications** - For OTP code alerts

### Browser Extension

The browser extension is required for autofill functionality:

1. Open your browser and navigate to `chrome://extensions`
2. Enable "Developer mode"
3. Click "Load unpacked" and select the `BrowserExtension` folder

## Project Structure

```
faktor-app/
├── Faktor/                      # Main macOS app
│   ├── FaktorApp.swift          # App entry point
│   ├── Models/                  # Data models
│   ├── Data/                    # Business logic managers
│   │   ├── MessageManager.swift # SMS database queries
│   │   ├── BrowserManager.swift # Browser extension communication
│   │   └── AppStateManager.swift# Permission & state management
│   ├── OTPParser/               # OTP extraction logic
│   │   ├── OTPParser.swift      # Main parsing engine
│   │   └── CustomOTPParsers.swift# Service-specific parsers
│   └── UI/                      # SwiftUI views
│       ├── Menu/                # Menu bar UI
│       ├── Settings/            # Settings window
│       └── Onboarding/          # Permission setup flow
├── BrowserExtension/            # Chrome extension (Manifest V3)
│   ├── manifest.json
│   ├── service-worker.js        # Background worker
│   └── content.js               # Content script with autofill UI
├── FaktorNativeHost/            # Native messaging bridge
│   ├── main.swift               # CLI tool for browser communication
│   └── README.md                # Setup documentation
└── FaktorTests/                 # Unit tests
```

## Development

### Building the macOS App

```bash
xcodebuild -scheme faktor -configuration Debug build
```

### Building the Native Host

The native host is built automatically with the main app. For standalone builds:

```bash
cd FaktorNativeHost
./build.sh
```

### Running Tests

```bash
xcodebuild test -scheme faktor
```

## Technology Stack

- **SwiftUI** - Native macOS UI
- **SQLite.swift** - Database queries
- **Combine** - Reactive data flow
- **Chrome Native Messaging** - Browser communication

## Supported Services

Faktor includes built-in parsers for 100+ services including:

- Google, Apple, Microsoft, Amazon
- GitHub, GitLab, Bitbucket
- Twitter/X, LinkedIn, Discord
- Stripe, PayPal, Square
- And many more...

Custom parsers can be added in `OTPParser/CustomOTPParsers.swift`.

## Privacy

- **Local Only** - All data processing happens on your device
- **No Cloud Sync** - OTP codes are never transmitted externally
- **Minimal Permissions** - Only requests necessary system permissions
- **Open Source** - Full transparency into how your data is handled

## Troubleshooting

### "Full Disk Access required"
Go to System Settings → Privacy & Security → Full Disk Access and enable Faktor.

### Browser extension not connecting
1. Ensure Faktor.app is running
2. Check that native messaging manifests are installed:
   ```bash
   ls ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/
   ```
3. Restart your browser

### OTP codes not detected
- Verify SMS messages are syncing to your Mac via iMessage
- Check Settings → General → Enable message monitoring

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [SQLite.swift](https://github.com/stephencelis/SQLite.swift) - Database wrapper
- [FluidMenuBarExtra](https://github.com/lfrb/FluidMenuBarExtra) - Menu bar component
