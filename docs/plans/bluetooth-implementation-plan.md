# Bluetooth Classic Connection Implementation Plan

## Overview
Add Bluetooth Classic (Serial Port Profile) connectivity to the hexapod robot control app as an alternative to WiFi/WebSocket. Use a hardcoded boolean to switch between connection types.

## Requirements Summary
- **Protocol**: Bluetooth Classic (SPP/Serial) - not BLE
- **Discovery**: Auto-discover devices by name (e.g., "robot-spider" or "HC-05")
- **Configuration**: Hardcoded boolean constant (no runtime UI toggle)
- **Error Handling**: Show error message, manual retry (no auto-fallback)
- **Default**: Bluetooth will be the new default connection method

## Architecture Changes

### Phase 1: Create Abstraction Layer (Foundation)

**Objective**: Introduce abstraction interfaces without breaking existing WiFi functionality.

#### 1.1 Create Connection Service Interface
**File**: `lib/services/connection_service.dart`

Define abstract interface for all connection types:
```dart
abstract class ConnectionService {
  Stream<ConnectionStatus> get statusStream;
  Stream<String> get messageStream;
  ConnectionStatus get status;
  bool get isConnected;
  Future<bool> connect(String address, int port);
  Future<void> disconnect();
  Future<void> sendCommand(RobotCommand command);
  void dispose();
}
```

#### 1.2 Create Discovery Service Interface
**File**: `lib/services/discovery_service.dart`

Define abstract interface for device discovery:
```dart
abstract class DiscoveryService {
  Future<RobotDevice?> discoverRobot({Duration timeout});
  Stream<RobotDevice?> watchForRobot({Duration interval});
}
```

#### 1.3 Create Connection Type Enum & Factory
**File**: `lib/services/connection_factory.dart`

```dart
enum ConnectionType {
  wifi,
  bluetooth,
}

class ConnectionFactory {
  static ConnectionService createConnectionService(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
        return WebSocketService();
      case ConnectionType.bluetooth:
        return BluetoothConnectionService();
    }
  }

  static DiscoveryService createDiscoveryService(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
        return MdnsDiscoveryService();
      case ConnectionType.bluetooth:
        return BluetoothDiscoveryService();
    }
  }
}
```

#### 1.4 Create Configuration File
**File**: `lib/config/connection_config.dart`

```dart
import '../services/connection_factory.dart';

class ConnectionConfig {
  /// Default connection type for the robot
  /// Set to ConnectionType.wifi for WiFi/WebSocket
  /// Set to ConnectionType.bluetooth for Bluetooth Classic
  static const ConnectionType defaultConnectionType = ConnectionType.bluetooth;

  /// Robot name for Bluetooth discovery
  /// The app will search for devices containing this name
  static const String bluetoothDeviceName = 'robot-spider';

  /// WiFi settings (used when defaultConnectionType == wifi)
  static const String wifiHostname = 'robot-spider.local';
  static const int wifiPort = 8080;
}
```

#### 1.5 Refactor Existing Services
**Files**:
- `lib/services/websocket_service.dart` - Add `implements ConnectionService`
- `lib/services/mdns_discovery_service.dart` - Add `implements DiscoveryService`

No logic changes, just interface compliance.

#### 1.6 Update RobotConnectionProvider
**File**: `lib/providers/robot_connection_provider.dart`

**Changes**:
- Replace concrete service types with interfaces
- Use ConnectionFactory to instantiate services based on config
- Add connection type awareness

```dart
class RobotConnectionProvider extends ChangeNotifier {
  late final DiscoveryService _discoveryService;
  late final ConnectionService _connectionService;
  final ConnectionType _connectionType;

  RobotConnectionProvider({
    ConnectionType? connectionType,
  }) : _connectionType = connectionType ?? ConnectionConfig.defaultConnectionType {
    _discoveryService = ConnectionFactory.createDiscoveryService(_connectionType);
    _connectionService = ConnectionFactory.createConnectionService(_connectionType);

    // ... rest of initialization
  }
}
```

### Phase 2: Implement Bluetooth Services

#### 2.1 Add Bluetooth Dependencies
**File**: `pubspec.yaml`

Add package:
```yaml
dependencies:
  flutter_bluetooth_serial: ^0.4.0  # Bluetooth Classic support
  permission_handler: ^11.0.0       # Android runtime permissions
```

#### 2.2 Configure Android Permissions
**File**: `android/app/src/main/AndroidManifest.xml`

Add Bluetooth permissions:
```xml
<!-- Bluetooth Classic permissions -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<uses-feature android:name="android.hardware.bluetooth" android:required="false" />
```

#### 2.3 Implement Bluetooth Connection Service
**File**: `lib/services/bluetooth/bluetooth_connection_service.dart`

**Responsibilities**:
- Manage Bluetooth Classic RFCOMM connection
- Send/receive data via Serial Port Profile
- Handle connection lifecycle (connect, disconnect, errors)
- Provide status and message streams

**Key Implementation Details**:
```dart
class BluetoothConnectionService implements ConnectionService {
  BluetoothConnection? _connection;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _messageController = StreamController<String>.broadcast();

  Future<bool> connect(String macAddress, int port) async {
    try {
      _statusController.add(ConnectionStatus.connecting);

      // Establish RFCOMM connection
      _connection = await BluetoothConnection.toAddress(macAddress);

      // Send init command
      await sendCommand(RobotCommand.init);

      // Listen for incoming data
      _connection!.input!.listen(_handleIncomingData);

      _statusController.add(ConnectionStatus.connected);
      return true;
    } catch (e) {
      _statusController.add(ConnectionStatus.error);
      return false;
    }
  }

  Future<void> sendCommand(RobotCommand command) async {
    _connection?.output.add(utf8.encode(command.commandString));
    await _connection?.output.allSent;
  }
}
```

**Protocol Notes**:
- Messages sent as UTF-8 encoded bytes
- Same command strings as WiFi: "init", "forward", "backward", "left", "right"
- No changes needed to robot firmware protocol

#### 2.4 Implement Bluetooth Discovery Service
**File**: `lib/services/bluetooth/bluetooth_discovery_service.dart`

**Responsibilities**:
- Scan for nearby Bluetooth devices
- Filter by device name (contains "robot-spider" or configured name)
- Handle pairing if needed
- Return RobotDevice with MAC address

**Key Implementation Details**:
```dart
class BluetoothDiscoveryService implements DiscoveryService {
  Future<RobotDevice?> discoverRobot({Duration timeout = const Duration(seconds: 5)}) async {
    // Check Bluetooth enabled
    bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (!isEnabled) return null;

    // Request permissions
    await _requestPermissions();

    // Get paired devices first (fast)
    List<BluetoothDevice> bondedDevices =
      await FlutterBluetoothSerial.instance.getBondedDevices();

    for (var device in bondedDevices) {
      if (device.name?.contains(ConnectionConfig.bluetoothDeviceName) ?? false) {
        return RobotDevice(
          name: device.name!,
          ipAddress: device.address,  // MAC address stored as ipAddress
          port: 0,  // Not used for Bluetooth
        );
      }
    }

    // If not found in paired, start discovery
    List<BluetoothDiscoveryResult> results =
      await FlutterBluetoothSerial.instance.startDiscovery().toList();

    for (var result in results) {
      if (result.device.name?.contains(ConnectionConfig.bluetoothDeviceName) ?? false) {
        return RobotDevice(
          name: result.device.name!,
          ipAddress: result.device.address,
          port: 0,
        );
      }
    }

    return null;
  }
}
```

#### 2.5 Handle Permissions
**File**: `lib/services/bluetooth/bluetooth_permission_handler.dart`

```dart
class BluetoothPermissionHandler {
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    }
    return true;  // iOS handles automatically
  }
}
```

### Phase 3: Update UI & User Experience

#### 3.1 Update Setup Screen
**File**: `lib/screens/setup_screen.dart`

**Changes**:
- Show connection type in UI (read-only display)
- Update discovery messages based on connection type
- Handle Bluetooth-specific error messages

```dart
Widget _buildDiscoverySection(RobotConnectionProvider provider) {
  final connectionType = provider.connectionType;
  final searchMessage = connectionType == ConnectionType.wifi
      ? 'Searching for robot-spider.local...'
      : 'Searching for Bluetooth device...';

  // ... rest of UI
}
```

#### 3.2 Add Connection Type Indicator
Display current connection method to user:
```dart
Row(
  children: [
    Icon(
      connectionType == ConnectionType.wifi
        ? Icons.wifi
        : Icons.bluetooth,
    ),
    Text('Connection: ${connectionType.name.toUpperCase()}'),
  ],
)
```

### Phase 4: Testing & Validation

#### 4.1 Create Test Robot Server (Bluetooth)
**File**: `mock_robot/mock_bluetooth_server.py`

Python script using PyBluez for testing:
```python
import bluetooth

server_sock = bluetooth.BluetoothSocket(bluetooth.RFCOMM)
server_sock.bind(("", bluetooth.PORT_ANY))
server_sock.listen(1)

# Advertise service
bluetooth.advertise_service(
    server_sock, "robot-spider",
    service_id=uuid,
    service_classes=[uuid, bluetooth.SERIAL_PORT_CLASS],
)

# Accept connections and echo commands
client_sock, address = server_sock.accept()
while True:
    data = client_sock.recv(1024)
    print(f"Received: {data.decode('utf-8')}")
```

#### 4.2 Add Makefile Targets
**File**: `Makefile`

```makefile
# Bluetooth mock server targets
bt-server-setup:
	@cd mock_robot && pip3 install pybluez

bt-server-run:
	@cd mock_robot && python3 mock_bluetooth_server.py
```

#### 4.3 Manual Testing Checklist
- [ ] Bluetooth discovery finds device by name
- [ ] Pairing dialog appears (if not paired)
- [ ] Connection establishes successfully
- [ ] "init" command sent automatically
- [ ] Forward/backward/left/right commands work
- [ ] Disconnection works cleanly
- [ ] Error messages are clear
- [ ] Switching config between WiFi/Bluetooth works

### Phase 5: Documentation

#### 5.1 Update README
**File**: `README.md`

Add Bluetooth section:
```markdown
## Connection Types

### Bluetooth (Default)
- Auto-discovers robot by Bluetooth device name
- Uses Bluetooth Classic (SPP)
- No WiFi network required
- Requires Android location permission

### WiFi (Alternative)
- Auto-discovers via mDNS (robot-spider.local)
- Requires same WiFi network
- Change in `lib/config/connection_config.dart`
```

#### 5.2 Create Bluetooth Setup Guide
**File**: `docs/bluetooth-setup.md`

Document:
- How to configure ESP32/Arduino for Bluetooth Classic
- Pairing instructions
- Troubleshooting common issues
- Switching between WiFi and Bluetooth

## Critical Files to Modify

### New Files (13 files)
1. `lib/services/connection_service.dart` - Abstract interface
2. `lib/services/discovery_service.dart` - Abstract interface
3. `lib/services/connection_factory.dart` - Factory pattern
4. `lib/config/connection_config.dart` - Configuration constants
5. `lib/services/bluetooth/bluetooth_connection_service.dart` - BT implementation
6. `lib/services/bluetooth/bluetooth_discovery_service.dart` - BT discovery
7. `lib/services/bluetooth/bluetooth_permission_handler.dart` - Permissions
8. `mock_robot/mock_bluetooth_server.py` - Test server
9. `mock_robot/requirements-bluetooth.txt` - PyBluez deps
10. `docs/bluetooth-setup.md` - Documentation
11. `test/services/connection_factory_test.dart` - Unit tests
12. `test/services/bluetooth_connection_service_test.dart` - BT tests
13. `test/services/bluetooth_discovery_service_test.dart` - Discovery tests

### Modified Files (8 files)
1. `lib/providers/robot_connection_provider.dart` - Use factory, add type awareness
2. `lib/services/websocket_service.dart` - Implement ConnectionService
3. `lib/services/mdns_discovery_service.dart` - Implement DiscoveryService
4. `lib/screens/setup_screen.dart` - Show connection type
5. `pubspec.yaml` - Add Bluetooth packages
6. `android/app/src/main/AndroidManifest.xml` - Add permissions
7. `Makefile` - Add BT server targets
8. `README.md` - Document Bluetooth support

## Data Model Changes

### RobotDevice Reuse
The existing `RobotDevice` model works for both connection types:
- **WiFi**: `ipAddress` = "192.168.1.100", `port` = 8080
- **Bluetooth**: `ipAddress` = "AA:BB:CC:DD:EE:FF" (MAC), `port` = 0 (unused)

No changes needed to the model.

## Implementation Order

1. **Phase 1** (Foundation) - 2-3 hours
   - Create interfaces
   - Create factory
   - Create config file
   - Update existing services
   - Update provider

2. **Phase 2** (Bluetooth) - 3-4 hours
   - Add dependencies
   - Configure permissions
   - Implement Bluetooth connection service
   - Implement Bluetooth discovery service
   - Handle permissions

3. **Phase 3** (UI) - 1 hour
   - Update setup screen
   - Add connection type indicator

4. **Phase 4** (Testing) - 2 hours
   - Create mock Bluetooth server
   - Manual testing
   - Fix issues

5. **Phase 5** (Documentation) - 1 hour
   - Update README
   - Create Bluetooth setup guide

**Total Estimated Time**: 9-11 hours

## Risk Mitigation

### Low Risk
- Phase 1 changes are purely additive
- Existing WiFi functionality unaffected
- Can test each phase independently

### Medium Risk
- Bluetooth permissions on Android 12+
- Device discovery might be slow
- Pairing dialog UX

### Mitigation Strategies
- Thorough testing with Android 12+ devices
- Clear error messages for permission issues
- Add timeout handling for discovery
- Document pairing process clearly

## Verification Steps

### End-to-End Testing

**WiFi Connection (Regression Test)**:
1. Set `ConnectionConfig.defaultConnectionType = ConnectionType.wifi`
2. Build and run: `make build && make install`
3. Start mock WiFi server: `make mock-robot-run`
4. Open app, verify auto-discovery works
5. Connect and test all movement commands
6. Verify disconnect works

**Bluetooth Connection (New Feature)**:
1. Set `ConnectionConfig.defaultConnectionType = ConnectionType.bluetooth`
2. Build and run: `make build && make install`
3. Start mock Bluetooth server (ESP32 or Python script)
4. Open app, verify Bluetooth discovery works
5. Accept pairing dialog if needed
6. Connect and test all movement commands
7. Verify disconnect works

**Configuration Switching**:
1. Switch config between WiFi and Bluetooth
2. Rebuild app
3. Verify correct connection type is used
4. No crashes or errors

## Success Criteria

- [x] WiFi connection still works (no regression)
- [ ] Bluetooth connection establishes successfully
- [ ] Device discovery works for both types
- [ ] All movement commands work via Bluetooth
- [ ] Clean error messages for Bluetooth issues
- [ ] Config switch requires only one constant change
- [ ] No UI changes needed (except connection type indicator)
- [ ] Documentation updated
- [ ] Manual tests pass

## Notes

- Bluetooth Classic (not BLE) chosen for simplicity and compatibility
- No runtime switching UI - keeps implementation simple
- Hardcoded config approach minimizes UI changes
- Same command protocol for both connection types
- RobotDevice model reused without modification
- Provider pattern maintained throughout
