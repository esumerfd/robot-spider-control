# Hexapod Control - Requirements Document

## Project Overview

**Application Name:** Hexapod Control
**Platform:** Android (Flutter)
**Purpose:** Remote control application for hexapod robots over network connection

## Target Platform

**Primary Target:**
- Android devices (phones and tablets)
- Minimum SDK version: TBD
- Target SDK version: Latest stable Android

**Future Considerations:**
- iOS support (deferred)
- Web interface (deferred)
- Desktop controls (deferred)

## Functional Requirements

### FR-1: Network Connectivity

**Description:** The application must establish and maintain network connection to a hexapod robot.

**Requirements:**
- **Bonjour/mDNS Discovery:** Automatic discovery of hexapod robots on local network using Bonjour protocol (mDNS/Zeroconf)
- Display list of discovered hexapod devices with device name and IP address
- Manual IP address entry option as fallback
- Connection status indication (connected/disconnected)
- Automatic reconnection on connection loss
- Connection timeout handling
- Network protocol: TBD (TCP/UDP/WebSocket - to be determined based on hexapod implementation)

### FR-2: Setup Panel

**Description:** A dedicated UI panel for configuring and establishing connection to the hexapod.

**Requirements:**
- **Auto-discovery list:** Display hexapod robots discovered via Bonjour/mDNS with device name and IP
- **Refresh button:** Re-scan network for available devices
- **Discovery indicator:** Show scanning/searching animation while discovering devices
- Allow manual IP address input as fallback option
- Display connection port configuration
- Show connection status with visual feedback
- Provide "Connect" and "Disconnect" actions
- Display robot information when connected (name, IP, status)
- Persist last successful connection settings
- Handle "no devices found" state with helpful message

### FR-3: Control Panel

**Description:** A UI panel providing directional control of the hexapod robot.

**Control Requirements:**
- **Forward** button - Move robot forward
- **Backward** button - Move robot backward
- **Turn Left** button - Rotate robot counter-clockwise
- **Turn Right** button - Rotate robot clockwise
- All controls active only when connected to robot
- Visual feedback for button presses
- Command transmission to robot over network

## UI/UX Requirements

### UX-1: User Interface Layout

**Setup Panel:**
- Clean, simple layout focused on connection workflow
- **Device discovery list** showing available hexapods with device names
- Refresh button with icon to re-scan network
- Loading/scanning indicator during device discovery
- Expandable manual connection option with IP address and port input fields
- Large, clear "Connect" button for each discovered device
- Status indicator (color-coded: red=disconnected, green=connected, yellow=connecting)
- "No devices found" message with troubleshooting tips
- Error messages displayed clearly

**Control Panel:**
- Intuitive button layout for directional controls
- Large, touch-friendly buttons (minimum 48x48 dp)
- Visual feedback on button press (pressed state)
- Disabled state when not connected to robot
- Emergency stop button (future consideration)

### UX-2: Navigation

- Tab-based or drawer navigation between Setup and Control panels
- Direct access to both panels
- Control panel accessible only when connected (or with warning)

### UX-3: Accessibility

- Adequate touch target sizes (minimum 48x48 dp)
- Clear button labels
- Color-coded status indicators with text labels
- Support for portrait and landscape orientations

## Technical Requirements

### TR-1: Architecture

**Framework:** Flutter (latest stable)
**Language:** Dart
**State Management:** TBD (Provider/Riverpod/Bloc)

**Recommended Structure:**
```
lib/
  ├── models/          # Data models (Robot, Connection)
  ├── services/        # Network services, robot communication
  ├── providers/       # State management
  ├── screens/         # Setup and Control screens
  ├── widgets/         # Reusable UI components
  └── main.dart        # Application entry point
```

### TR-2: Network Communication

**Discovery Protocol:** Bonjour/mDNS (multicast DNS)
- **Service Name:** `robot-spider.local`
- **Flutter Package:** `multicast_dns` for device discovery
- Continuous scanning with periodic refresh
- Resolve hostname to IP address

**Communication Protocol:** WebSocket
**Data Format:** Text-based commands
**Connection Management:**
- Keep-alive mechanism
- Timeout handling (5-10 seconds)
- Retry logic on connection failure

**Command Format:**

Supported Commands (text-based messages over WebSocket):
- `init` - Initialize connection with hexapod
- `forward` - Move robot forward
- `backward` - Move robot backward
- `left` - Turn robot left
- `right` - Turn robot right

**Example WebSocket Message Flow:**
```
Client → Server: "init"
Server → Client: (acknowledgment or ready status)

Client → Server: "forward"
Client → Server: "left"
Client → Server: "backward"
```

**mDNS Discovery Flow:**
1. Use `multicast_dns` package to resolve `robot-spider.local`
2. Query for A records to get IP address
3. Resolve hostname to IPv4 address
4. Display discovered device in UI
5. User selects device to connect
6. Establish WebSocket connection to `ws://<ip-address>:<port>/`

### TR-3: Device Requirements

**Minimum Requirements:**
- Android 7.0 (API level 24) or higher
- Network capability (WiFi)
- Minimum 2GB RAM

**Permissions Required:**
- Internet access (`INTERNET`)
- Network state access (`ACCESS_NETWORK_STATE`)
- WiFi state access (`ACCESS_WIFI_STATE`)
- Change WiFi multicast state (`CHANGE_WIFI_MULTICAST_STATE`) - Required for mDNS discovery

### TR-4: Error Handling

- Network connection errors
- Timeout errors
- Invalid IP address validation
- Connection lost during operation
- Robot unreachable errors
- mDNS discovery failures (no devices found, multicast not supported)
- WiFi not connected error
- Permission denied errors

**Error Display:**
- User-friendly error messages
- Suggested actions for resolution (e.g., "Ensure you're connected to WiFi", "Check if robot is powered on")
- Error logging for debugging

## Non-Functional Requirements

### NFR-1: Performance

- Connection establishment: < 3 seconds
- Command response time: < 100ms
- UI responsiveness: 60 FPS minimum
- Low latency for real-time control

### NFR-2: Reliability

- Handle network interruptions gracefully
- Automatic reconnection on network recovery
- No crashes on connection loss
- Proper resource cleanup on app close

### NFR-3: Usability

- Intuitive interface requiring no training
- Clear visual feedback for all actions
- Minimal steps to establish connection
- Obvious control button layout

### NFR-4: Security

- Optional authentication for robot connection (future)
- Secure communication protocol (future consideration)
- No storage of sensitive credentials in plain text

## User Stories

### US-1: First Time Connection
**As a user**, I want to easily discover and connect to my hexapod robot on the network, so that I can start controlling it quickly.

**Acceptance Criteria:**
- App automatically discovers hexapod robots on the local network using Bonjour/mDNS
- User sees a list of available devices with names
- User can tap a device to connect
- User can manually enter robot IP address as fallback
- User can refresh the device list
- User sees clear connection status
- User receives feedback if connection fails

### US-2: Robot Control
**As a user**, I want to control my hexapod's movement using simple directional buttons, so that I can navigate it around obstacles.

**Acceptance Criteria:**
- Forward button moves robot forward
- Backward button moves robot backward
- Turn left/right buttons rotate robot
- Controls only work when connected
- Visual feedback on button press

### US-3: Reconnection
**As a user**, if my connection is lost, I want the app to automatically reconnect, so that I don't have to manually reconnect each time.

**Acceptance Criteria:**
- App detects connection loss
- App attempts automatic reconnection
- User is notified of connection status changes

## Future Enhancements (Out of Scope for v1.0)

- Speed control (variable movement speed)
- Emergency stop button
- Battery level indicator
- Camera feed from robot
- Custom movement patterns/macros
- Multiple robot support
- Gesture-based controls (swipe to move)
- Voice commands
- Offline mode with Bluetooth fallback
- Robot status telemetry (temperature, sensor data)

## Hexapod Robot Specifications

**Network Configuration:**
- **Hostname:** `robot-spider.local` (mDNS)
- **Protocol:** WebSocket
- **Port:** TBD (default 80 or 8080 recommended)
- **Network:** Home WiFi with DHCP

**Supported Commands:**
- `init` - Initialize connection
- `forward` - Move forward
- `backward` - Move backward
- `left` - Turn left
- `right` - Turn right

**Response Format:** TBD (acknowledgment messages, status updates)

## Open Questions

1. **What port does the hexapod WebSocket server listen on?** (recommend 80, 8080, or 8765)
2. **Does the robot send acknowledgment responses?** (e.g., "OK", "READY", error messages)
3. **Connection initialization:** Is `init` command required before sending movement commands?
4. **Command timing:** Should commands be sent on button press, button hold, or button release?
5. **Speed control:** Are commands fixed speed, or will speed control be added later?
6. **Hexapod firmware platform:** ESP32, Raspberry Pi, Arduino, or other?

## Success Criteria

**Version 1.0 is successful if:**
- App automatically discovers hexapod robots on local network via Bonjour/mDNS
- User can see and select discovered devices
- User can connect to hexapod robot from discovered list or via manual IP address
- User can control forward/backward movement
- User can control left/right turning
- Connection status is clearly visible
- App handles connection errors gracefully
- UI is responsive and intuitive

## Timeline Considerations

**Phase 1: Basic Connectivity**
- Bonjour/mDNS discovery implementation
- Device list UI in setup panel
- Manual IP entry fallback
- Network connection logic
- Connection status display

**Phase 2: Control Implementation**
- Control panel UI
- Command transmission
- Button feedback

**Phase 3: Polish & Testing**
- Error handling
- UI/UX refinement
- Testing on real hardware
- Bug fixes

## Recommended Flutter Packages

### Required Flutter Packages

**mDNS Discovery:**
- **Package:** `multicast_dns`
- **Purpose:** Resolve `robot-spider.local` to IP address
- **Link:** https://pub.dev/packages/multicast_dns

**WebSocket Communication:**
- **Package:** `web_socket_channel`
- **Purpose:** WebSocket client for sending commands to hexapod
- **Link:** https://pub.dev/packages/web_socket_channel

**State Management:**
- **Package:** `provider` or `riverpod`
- **Purpose:** Manage app state (connection status, discovered devices)
- **Link:** https://pub.dev/packages/provider

**Storage:**
- **Package:** `shared_preferences`
- **Purpose:** Persist last connected device
- **Link:** https://pub.dev/packages/shared_preferences

**Optional Packages:**
- **Permission Handling:** `permission_handler` (if needed for Android 12+)

## Related Documents

- Technical Architecture: TBD
- API Specification: TBD
- Hexapod Robot Protocol Documentation: TBD
- User Manual: TBD
