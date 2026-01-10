# Hexapod Control

A Flutter Android app for controlling hexapod robots over WiFi or Bluetooth with automatic device discovery.

## Overview

This app provides a simple interface to discover and control hexapod robots. It supports two connection methods:
- **Bluetooth Classic (SPP)** - Direct wireless connection (default)
- **WiFi (WebSocket)** - Network-based connection via mDNS

**Features:**
- Dual connectivity: Bluetooth Classic and WiFi
- Auto-discovery (Bluetooth device scan or mDNS)
- Manual connection fallback
- Real-time control with directional buttons
- Simple configuration switching

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
# WiFi Mock Server
make mock-setup         # One-time setup
make mock-robot-run     # Start WiFi mock server

# Bluetooth Mock Server
make bt-server-setup    # One-time setup
make bt-server-run      # Start Bluetooth mock server
```

## Connection Types

The app supports two connection methods, selectable via hardcoded configuration:

### Bluetooth Classic (Default)
- **Protocol**: Bluetooth Serial Port Profile (SPP/RFCOMM)
- **Discovery**: Scans for nearby devices by name
- **Advantages**: Direct connection, no WiFi network required
- **Requirements**: Android location permission (required for Bluetooth scanning)
- **Range**: ~10 meters

**Configuration:**
```dart
// lib/config/connection_config.dart
static const ConnectionType defaultConnectionType = ConnectionType.bluetooth;
static const String bluetoothDeviceName = 'robot-spider';
```

### WiFi (Alternative)
- **Protocol**: WebSocket over WiFi
- **Discovery**: mDNS (robot-spider.local)
- **Advantages**: Longer range, network integration
- **Requirements**: Same WiFi network as robot
- **Range**: ~50+ meters (depends on WiFi)

**Configuration:**
```dart
// lib/config/connection_config.dart
static const ConnectionType defaultConnectionType = ConnectionType.wifi;
static const String wifiHostname = 'robot-spider.local';
static const int wifiPort = 8080;
```

To switch between connection types:
1. Edit `lib/config/connection_config.dart`
2. Change `defaultConnectionType` constant
3. Rebuild the app: `make build`

## Usage

1. **Setup Screen**: Connect to your robot
   - App auto-discovers `robot-spider.local`
   - Or manually enter IP address and port
   - Tap "Connect"

2. **Control Screen**: Drive your robot
   - Use Forward/Backward/Left/Right buttons
   - Connection status shown at top

## Robot Requirements

### For Bluetooth Connection (Default)
Your hexapod must:
- Have Bluetooth Classic enabled (not BLE)
- Advertise with device name containing "robot-spider"
- Accept RFCOMM connections on Serial Port Profile
- Accept these text commands: `init`, `forward`, `backward`, `left`, `right`

### For WiFi Connection
Your hexapod must:
- Join the same WiFi network as the phone
- Advertise as `robot-spider.local` via mDNS
- Run a WebSocket server (default port: 8080)
- Accept these text commands: `init`, `forward`, `backward`, `left`, `right`

### Command Protocol
Both connection types use the same text-based command protocol:
- `init` - Initialize robot
- `forward` - Move forward
- `backward` - Move backward
- `left` - Turn left
- `right` - Turn right

**Testing Without Physical Hardware:**

Mock robot servers are included for both connection types:

**WiFi Mock Server:**
- Located in `/mock_robot/mock_robot_server.py`
- WebSocket server with mDNS advertisement
- See [Mock Robot README](mock_robot/README.md)

**Bluetooth Mock Server:**
- Located in `/mock_robot/mock_bluetooth_server.py`
- Bluetooth Classic RFCOMM server
- Advertises as "robot-spider" via SPP
- **Note**: PyBluez has compatibility issues with Python 3.12+
- See [Bluetooth Testing Guide](mock_robot/BLUETOOTH_TESTING.md) for alternatives
- **Recommended**: Test Bluetooth with ESP32 or Arduino hardware instead

## Technical Details

**Stack:**
- Flutter with Provider state management
- Factory pattern for connection abstraction
- **Bluetooth**: `flutter_bluetooth_serial` for Bluetooth Classic (SPP)
- **WiFi**: `multicast_dns` for mDNS discovery, `web_socket_channel` for WebSocket
- `permission_handler` for Android runtime permissions

**Architecture:**
- Abstract `ConnectionService` interface for both WiFi and Bluetooth
- Abstract `DiscoveryService` interface for device discovery
- `ConnectionFactory` creates appropriate services based on configuration
- Same `RobotConnectionProvider` manages both connection types

**Bluetooth Protocol:**
```
1. Scan for paired/nearby Bluetooth devices
2. Filter by device name (contains "robot-spider")
3. Connect via RFCOMM
4. Send UTF-8 encoded text commands
```

**WiFi Protocol:**
```
1. Discover robot via mDNS (robot-spider.local)
2. Connect to ws://<ip>:8080
3. Send text commands over WebSocket
```

Both protocols use identical command strings: `init`, `forward`, `backward`, `left`, `right`

## Project Structure

```
lib/
├── models/                 # Data models (RobotDevice, ConnectionStatus, RobotCommand)
├── config/                 # Configuration
│   └── connection_config.dart   # Connection type selection
├── services/               # Connection services
│   ├── connection_service.dart  # Abstract interface
│   ├── discovery_service.dart   # Abstract interface
│   ├── connection_factory.dart  # Factory for creating services
│   ├── websocket_service.dart   # WiFi implementation
│   ├── mdns_discovery_service.dart  # WiFi discovery
│   └── bluetooth/
│       ├── bluetooth_connection_service.dart  # Bluetooth implementation
│       ├── bluetooth_discovery_service.dart   # Bluetooth discovery
│       └── bluetooth_permission_handler.dart  # Android permissions
├── providers/              # State management
│   └── robot_connection_provider.dart  # Main connection provider
├── screens/                # Setup & Control UI
│   ├── setup_screen.dart
│   └── control_screen.dart
└── main.dart

mock_robot/
├── mock_robot_server.py       # WiFi mock server (WebSocket + mDNS)
├── mock_bluetooth_server.py   # Bluetooth mock server (RFCOMM + SPP)
├── test_mdns.py               # mDNS resolution test utility
├── requirements.txt           # WiFi server dependencies
└── requirements-bluetooth.txt # Bluetooth server dependencies
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

**WiFi Mock Server:**
```bash
make mock-setup           # Setup Python environment (one-time)
make mock-robot-run       # Start WiFi mock server
make mock-robot-run-acks  # Start with acknowledgments enabled
make mock-test-mdns       # Test mDNS resolution
```

**Bluetooth Mock Server:**
```bash
make bt-server-setup      # Setup Bluetooth dependencies (one-time)
make bt-server-run        # Start Bluetooth mock server
make bt-server-run-acks   # Start with acknowledgments enabled
```

## Typical Development Workflow

### Testing with WiFi Connection

1. **Setup mock WiFi server** (first time only):
   ```bash
   make mock-setup
   ```

2. **Configure app for WiFi**:
   - Edit `lib/config/connection_config.dart`
   - Set `defaultConnectionType = ConnectionType.wifi`
   - Run `make build`

3. **Start mock WiFi server** (in one terminal):
   ```bash
   make mock-robot-run
   ```

4. **Build and run app** (in another terminal):
   ```bash
   make run
   ```

5. **Test the connection**:
   - App should auto-discover robot-spider.local
   - Or connect manually to the IP shown by mock server
   - Use control buttons to send commands
   - Watch mock server console for received commands

### Testing with Bluetooth Connection

**Note**: The Bluetooth mock server requires Python 3.10/3.11 due to PyBluez compatibility issues. For testing Bluetooth, we recommend:

#### Option 1: Use Real Hardware (Recommended)
1. **Flash ESP32 or Arduino** with Bluetooth Classic sketch
   - See [Bluetooth Testing Guide](mock_robot/BLUETOOTH_TESTING.md) for example code
   - Device name should contain "robot-spider"
   - Accept commands: init, forward, backward, left, right

2. **Configure app for Bluetooth** (if not already default):
   - Edit `lib/config/connection_config.dart`
   - Set `defaultConnectionType = ConnectionType.bluetooth`
   - Run `make build`

3. **Build and run app**:
   ```bash
   make run
   ```

4. **Test the connection**:
   - Enable Bluetooth on your Android device
   - App should discover "robot-spider" Bluetooth device
   - Accept pairing if prompted
   - Connect and test control commands

#### Option 2: Test WiFi Instead
The WiFi connection uses the same command protocol and is easier to test:
```bash
make mock-setup        # One-time setup
make mock-robot-run    # Start WiFi server
```

Then switch the app to WiFi mode and test. See [Bluetooth Testing Guide](mock_robot/BLUETOOTH_TESTING.md) for detailed alternatives.

## Documentation

- [Detailed Requirements](docs/design-hexapod-control.md)
- [Mock Robot Server Guide](mock_robot/README.md)

## License

MIT
