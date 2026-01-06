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
- Android Studio with Android SDK
- Android device or emulator
- Python 3.8+ (for mock robot server)

**View Available Commands:**
```bash
make help
```

**Build and Run:**
```bash
# Build the Android APK
make build

# Install on connected device/emulator
make install

# Build, install, and launch
make run
```

**Mock Robot Server (for testing):**
```bash
# One-time setup
make mock-setup

# Start mock robot server
make mock-robot-run

# Test mDNS resolution
make mock-test-mdns
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

**Testing Without Physical Hardware:**

A mock robot server is included for development and testing:
- Located in `/mock_robot`
- Implements the complete WebSocket protocol
- Advertises via mDNS as `robot-spider.local`
- Logs all received commands to console
- See [Mock Robot README](mock_robot/README.md) for details

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

mock_robot/
├── mock_robot_server.py  # Mock robot WebSocket server
├── test_mdns.py          # mDNS resolution test utility
└── requirements.txt      # Python dependencies
```

## Development Commands

**Android App:**
```bash
make build        # Build APK
make run          # Build, install, and launch
make install      # Install APK on device
make clean        # Clean build artifacts
make devices      # List connected devices
make emulator     # Start Android emulator
make test         # Run Flutter tests
make analyze      # Run Flutter analyzer
make format       # Format Dart code
```

**Mock Robot Server:**
```bash
make mock-setup           # Setup Python environment (one-time)
make mock-robot-run       # Start mock server
make mock-robot-run-acks  # Start with acknowledgments enabled
make mock-test-mdns       # Test mDNS resolution
```

## Typical Development Workflow

1. **Setup mock robot server** (first time only):
   ```bash
   make mock-setup
   ```

2. **Start mock server** (in one terminal):
   ```bash
   make mock-robot-run
   ```

3. **Build and run app** (in another terminal):
   ```bash
   make run
   ```

4. **Test the connection**:
   - App should auto-discover the mock robot
   - Or connect manually to the IP shown by the mock server
   - Use control buttons to send commands
   - Watch mock server console for received commands

5. **Verify mDNS is working**:
   ```bash
   make mock-test-mdns
   ```

## Documentation

- [Detailed Requirements](docs/design-hexapod-control.md)
- [Mock Robot Server Guide](mock_robot/README.md)

## License

MIT
