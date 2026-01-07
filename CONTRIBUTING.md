# Contributing to Faktor

Thank you for your interest in contributing to Faktor! This document provides guidelines and instructions for contributing.

## Getting Started

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15+
- Swift 5.9+

### Setting Up the Development Environment

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/faktor-app.git
   cd faktor-app
   ```

2. Open the project in Xcode:
   ```bash
   open faktor.xcodeproj
   ```

3. Build and run the project (⌘R)

## How to Contribute

### Reporting Bugs

Before submitting a bug report:
- Check existing issues to avoid duplicates
- Collect relevant information (macOS version, browser version, steps to reproduce)

When submitting a bug report, include:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Screenshots or logs if applicable
- System information (macOS version, browser)

### Suggesting Features

Feature requests are welcome! Please:
- Check existing issues for similar suggestions
- Provide a clear description of the feature
- Explain the use case and benefits
- Consider implementation complexity

### Pull Requests

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Follow the existing code style
   - Write clear commit messages
   - Add tests for new functionality
   - Update documentation as needed

3. **Test your changes**:
   ```bash
   xcodebuild test -scheme faktor
   ```

4. **Submit a pull request**:
   - Provide a clear description of the changes
   - Reference any related issues
   - Ensure CI checks pass

## Code Style

### Swift

- Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and concise

## Project Architecture

### macOS App (`faktor/`)

- **Models/** - Data structures (Message, ParsedOTP, AppState)
- **Data/** - Business logic managers (MessageManager, BrowserManager)
- **OTPParser/** - OTP extraction and parsing logic
- **UI/** - SwiftUI views organized by feature

### Browser Extension (`BrowserExtension/`)

- **service-worker.js** - Background service for native messaging
- **content.js** - Content script with autofill UI
- **manifest.json** - Extension configuration

### Native Host (`FaktorNativeHost/`)

- Bridge between browser extension and main app
- Uses Chrome Native Messaging protocol

## Adding OTP Parser Support

To add support for a new service:

1. Check if the service follows standard OTP formats (4-8 digit codes)
2. If custom parsing is needed, add a parser in `OTPParser/CustomOTPParsers.swift`
3. Add test cases in `FaktorTests/`
4. Run tests to verify parsing works correctly

## Testing

Unit tests are located in `FaktorTests/`:
- OTP parsing tests
- Message filtering tests

## Questions?

If you have questions, feel free to:
- Open a discussion issue
- Reach out to the maintainers

Thank you for contributing!
