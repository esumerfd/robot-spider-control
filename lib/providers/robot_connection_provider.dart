import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/robot_device.dart';
import '../models/connection_status.dart';
import '../models/robot_command.dart';
import '../models/robot_log_message.dart';
import '../models/log_messages.dart';
import '../services/connection_service.dart';
import '../services/discovery_service.dart';
import '../services/connection_factory.dart';
import '../config/connection_config.dart';

/// Provider for managing robot connection state and operations
class RobotConnectionProvider extends ChangeNotifier {
  late final DiscoveryService _discoveryService;
  late final ConnectionService _connectionService;
  final ConnectionType _connectionType;

  RobotDevice? _discoveredDevice;
  RobotDevice? _connectedDevice;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isDiscovering = false;
  String? _errorMessage;

  // Robot response logging
  final LogMessages _logMessages = LogMessages(maxSize: 50);
  StreamSubscription<String>? _messageSubscription;

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

  /// Current connection type being used
  ConnectionType get connectionType => _connectionType;

  /// Robot log messages
  List<RobotLogMessage> get logMessages => _logMessages.getAll();

  RobotConnectionProvider({
    ConnectionType? connectionType,
  }) : _connectionType = connectionType ?? ConnectionConfig.defaultConnectionType {
    // Create services using factory based on connection type
    _discoveryService = ConnectionFactory.createDiscoveryService(_connectionType);
    _connectionService = ConnectionFactory.createConnectionService(_connectionType);

    // Listen to connection status changes
    _connectionService.statusStream.listen((status) {
      _connectionStatus = status;
      if (status == ConnectionStatus.disconnected ||
          status == ConnectionStatus.error) {
        _connectedDevice = null;
      }
      notifyListeners();
    });

    // Listen to messages from robot
    _messageSubscription = _connectionService.messageStream.listen((message) {
      final parsed = RobotLogMessage.fromResponse(message);
      _logMessages.add(parsed);
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
        _errorMessage = _connectionType == ConnectionType.wifi
            ? 'Connect to ${ConnectionConfig.wifiHostname}'
            : 'Pair with ${ConnectionConfig.bluetoothDeviceName}';
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

    final success = await _connectionService.connect(
      device.ipAddress,
      device.port,
    );

    if (success) {
      _connectedDevice = device;
      _errorMessage = null;
      _logMessages.info('Connected to ${device.name}');
    } else {
      _errorMessage = 'Failed to connect to ${device.ipAddress}:${device.port}';
      _logMessages.error('Connection failed');
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
    await _connectionService.disconnect();
    _logMessages.info('Disconnected');
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

    await _connectionService.sendCommand(command);
  }

  /// Move robot forward
  Future<void> moveForward() => sendCommand(RobotCommand.forward);

  /// Move robot backward
  Future<void> moveBackward() => sendCommand(RobotCommand.backward);

  /// Turn robot left
  Future<void> turnLeft() => sendCommand(RobotCommand.left);

  /// Turn robot right
  Future<void> turnRight() => sendCommand(RobotCommand.right);

  /// Clear all log messages
  void clearLogs() {
    _logMessages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionService.dispose();
    super.dispose();
  }
}
