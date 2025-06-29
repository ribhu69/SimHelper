# iOS Simulator Manager

This project is a SwiftUI macOS app to help you manage your iOS Simulators more efficiently.

## Features

- **List all available iOS Simulators** grouped by iOS version.
- **Filter** devices by type: All, iPhone, or iPad.
- **Visual status indicators**:
  - Running simulators are highlighted in green and labeled "Running".
  - Stopped simulators are labeled "Stopped".
- **Start or terminate simulators** with a single click.
- **Tap a simulator** to view all installed apps on that device.
- **Launch any installed app** on a simulator directly from the app.
- **All shell commands are printed** to the console for transparency and debugging.

## Requirements

- macOS with Xcode installed (Xcode 15+ recommended for full features).
- Swift 5.7+.

## How it works

- Uses `xcrun simctl` to interact with simulators and apps.
- Uses `plutil` to convert simulator app lists to JSON for parsing.
- No global Git configuration is required; you can use local git settings for version control.

## Getting Started

1. Clone or copy this project.
2. Open in Xcode and run the app.
3. Use the UI to manage your simulators and installed apps.

## Example Use Cases

- Quickly see which simulators are running and start/stop them.
- Filter to only see iPhones or iPads.
- View and launch any app installed on a simulator.
- Use as a productivity tool for iOS development and testing.

---

**Enjoy managing your
