import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../connection_service.dart';
import '../../models/connection_status.dart';
import '../../models/robot_command.dart';

/// Service for managing Bluetooth Classic connection to the hexapod robot
class BluetoothConnectionService implements ConnectionService {
  BluetoothConnection? _connection;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _messageController = StreamController<String>.broadcast();

  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;

  @override
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  @override
  Stream<String> get messageStream => _messageController.stream;

  @override
  ConnectionStatus get status => _currentStatus;

  @override
  bool get isConnected => _currentStatus == ConnectionStatus.connected;

  /// Connect to the robot via Bluetooth Classic
  ///
  /// [address] should be the MAC address (e.g., "AA:BB:CC:DD:EE:FF")
  /// [port] is ignored for Bluetooth Classic (RFCOMM)
  @override
  Future<bool> connect(String address, int port) async {
    if (isConnected) {
      await disconnect();
    }

    try {
      _updateStatus(ConnectionStatus.connecting);

      // Establish RFCOMM connection to the Bluetooth device
      print('Connecting to Bluetooth device at $address...');
      _connection = await BluetoothConnection.toAddress(address);

      if (_connection == null || !_connection!.isConnected) {
        print('Failed to establish Bluetooth connection');
        _updateStatus(ConnectionStatus.error);
        return false;
      }

      print('Bluetooth connection established');

      // Listen for incoming data
      _connection!.input!.listen(
        _handleIncomingData,
        onError: (error) {
          print('Bluetooth error: $error');
          _updateStatus(ConnectionStatus.error);
          disconnect();
        },
        onDone: () {
          print('Bluetooth connection closed');
          _updateStatus(ConnectionStatus.disconnected);
        },
      );

      _updateStatus(ConnectionStatus.connected);

      // Send init command
      await sendCommand(RobotCommand.init);

      return true;
    } catch (e) {
      print('Bluetooth connection error: $e');
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.close();
      } catch (e) {
        print('Error closing Bluetooth connection: $e');
      }
      _connection = null;
    }
    _updateStatus(ConnectionStatus.disconnected);
  }

  @override
  Future<void> sendCommand(RobotCommand command) async {
    if (!isConnected) {
      print('Cannot send command: not connected');
      return;
    }

    try {
      final commandString = '${command.commandString}\n';
      final data = Uint8List.fromList(utf8.encode(commandString));

      _connection?.output.add(data);
      await _connection?.output.allSent;

      print('Sent Bluetooth command: $commandString');
    } catch (e) {
      print('Error sending Bluetooth command: $e');
    }
  }

  /// Handle incoming data from the Bluetooth connection
  void _handleIncomingData(Uint8List data) {
    try {
      final message = utf8.decode(data);
      print('Received Bluetooth message: $message');
      _messageController.add(message);
    } catch (e) {
      print('Error decoding Bluetooth message: $e');
    }
  }

  /// Update connection status and notify listeners
  void _updateStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  @override
  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
  }
}
