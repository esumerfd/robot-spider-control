# Hexapod Control

A Flutter Android app for controlling hexapod robots over WiFi with automatic network discovery and WebSocket communication.

## Overview

This app provides a simple interface to discover and control hexapod robots on your local network. It uses mDNS (Bonjour) to automatically find robots advertising as `robot-spider.local` and sends movement commands via WebSocket.

**Features:**
- Auto-discovery of robots via mDNS
- Manual IP entry fallback
- Real-time control with directional buttons
- WebSocket-based communication

## Quick Start

**Prerequisites:**
- Flutter SDK
- Android Studio with Android SDK
- Android device or emulator

**Build and Run:**
```bash
flutter pub get
flutter run
```

**Build APK:**
```bash
flutter build apk --release
```

## Usage

1. **Setup Screen**: Connect to your robot
   - App auto-discovers `robot-spider.local`
   - Or manually enter IP address and port
   - Tap "Connect"

2. **Control Screen**: Drive your robot
   - Use Forward/Backward/Left/Right buttons
   - Connection status shown at top

## Robot Requirements

Your hexapod must:
- Join the same WiFi network
- Advertise as `robot-spider.local` via mDNS
- Run a WebSocket server (default port: 8080)
- Accept these text commands: `init`, `forward`, `backward`, `left`, `right`

## Technical Details

**Stack:**
- Flutter with Provider state management
- `multicast_dns` for device discovery
- `web_socket_channel` for robot communication

**Protocol:**
```
1. Discover robot via mDNS (robot-spider.local)
2. Connect to ws://<ip>:8080
3. Send "init" command
4. Send movement commands (forward, backward, left, right)
```

## Project Structure

```
lib/
├── models/          # Data models
├── services/        # mDNS discovery & WebSocket
├── providers/       # State management
├── screens/         # Setup & Control UI
└── main.dart
```

## Documentation

- [Detailed Requirements](docs/design-hexapod-control.md)

## License

MIT
