import 'dart:async';
import '../models/connection_status.dart';
import '../models/robot_command.dart';

/// Abstract interface for all connection types (WiFi, Bluetooth, etc.)
abstract class ConnectionService {
  /// Stream of connection status changes
  Stream<ConnectionStatus> get statusStream;

  /// Stream of messages received from the robot
  Stream<String> get messageStream;

  /// Current connection status
  ConnectionStatus get status;

  /// Whether currently connected to the robot
  bool get isConnected;

  /// Connect to the robot at the specified address and port
  ///
  /// For WiFi: address is IP address, port is WebSocket port
  /// For Bluetooth: address is MAC address, port is ignored (can be 0)
  Future<bool> connect(String address, int port);

  /// Disconnect from the robot
  Future<void> disconnect();

  /// Send a command to the robot
  Future<void> sendCommand(RobotCommand command);

  /// Clean up resources
  void dispose();
}
