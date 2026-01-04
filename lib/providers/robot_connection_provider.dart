import 'package:flutter/foundation.dart';
import '../models/robot_device.dart';
import '../models/connection_status.dart';
import '../models/robot_command.dart';
import '../services/mdns_discovery_service.dart';
import '../services/websocket_service.dart';

/// Provider for managing robot connection state and operations
class RobotConnectionProvider extends ChangeNotifier {
  final MdnsDiscoveryService _discoveryService = MdnsDiscoveryService();
  final WebSocketService _webSocketService = WebSocketService();

  RobotDevice? _discoveredDevice;
  RobotDevice? _connectedDevice;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isDiscovering = false;
  String? _errorMessage;

  /// Currently discovered robot device
  RobotDevice? get discoveredDevice => _discoveredDevice;

  /// Currently connected robot device
  RobotDevice? get connectedDevice => _connectedDevice;

  /// Current connection status
  ConnectionStatus get connectionStatus => _connectionStatus;

  /// Whether currently discovering devices
  bool get isDiscovering => _isDiscovering;

  /// Error message if any
  String? get errorMessage => _errorMessage;

  /// Whether connected to a robot
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;

  RobotConnectionProvider() {
    // Listen to WebSocket status changes
    _webSocketService.statusStream.listen((status) {
      _connectionStatus = status;
      if (status == ConnectionStatus.disconnected ||
          status == ConnectionStatus.error) {
        _connectedDevice = null;
      }
      notifyListeners();
    });
  }

  /// Discover the hexapod robot on the network
  Future<void> discoverRobot() async {
    _isDiscovering = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final device = await _discoveryService.discoverRobot(
        timeout: const Duration(seconds: 5),
      );

      if (device != null) {
        _discoveredDevice = device;
        _errorMessage = null;
      } else {
        _discoveredDevice = null;
        _errorMessage = 'Robot not found. Ensure robot-spider.local is on the network.';
      }
    } catch (e) {
      _errorMessage = 'Discovery failed: $e';
      _discoveredDevice = null;
    } finally {
      _isDiscovering = false;
      notifyListeners();
    }
  }

  /// Connect to a discovered or manually specified robot
  Future<bool> connectToRobot(RobotDevice device) async {
    _errorMessage = null;
    notifyListeners();

    final success = await _webSocketService.connect(
      device.ipAddress,
      device.port,
    );

    if (success) {
      _connectedDevice = device;
      _errorMessage = null;
    } else {
      _errorMessage = 'Failed to connect to ${device.ipAddress}:${device.port}';
    }

    notifyListeners();
    return success;
  }

  /// Connect to manually entered IP address
  Future<bool> connectToManualIp(String ipAddress, int port) async {
    final device = RobotDevice.manual(
      ipAddress: ipAddress,
      port: port,
    );
    return connectToRobot(device);
  }

  /// Disconnect from the current robot
  Future<void> disconnect() async {
    await _webSocketService.disconnect();
    _connectedDevice = null;
    notifyListeners();
  }

  /// Send a movement command to the robot
  Future<void> sendCommand(RobotCommand command) async {
    if (!isConnected) {
      _errorMessage = 'Not connected to robot';
      notifyListeners();
      return;
    }

    await _webSocketService.sendCommand(command);
  }

  /// Move robot forward
  Future<void> moveForward() => sendCommand(RobotCommand.forward);

  /// Move robot backward
  Future<void> moveBackward() => sendCommand(RobotCommand.backward);

  /// Turn robot left
  Future<void> turnLeft() => sendCommand(RobotCommand.left);

  /// Turn robot right
  Future<void> turnRight() => sendCommand(RobotCommand.right);

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
