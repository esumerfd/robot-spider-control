import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/robot_command.dart';
import '../models/connection_status.dart';

/// Service for managing WebSocket connection to the hexapod robot
class WebSocketService {
  WebSocketChannel? _channel;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _messageController = StreamController<String>.broadcast();

  ConnectionStatus _currentStatus = ConnectionStatus.disconnected;

  /// Stream of connection status changes
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Stream of messages received from the robot
  Stream<String> get messageStream => _messageController.stream;

  /// Current connection status
  ConnectionStatus get status => _currentStatus;

  /// Whether currently connected to the robot
  bool get isConnected => _currentStatus == ConnectionStatus.connected;

  /// Connect to the hexapod robot at the specified IP address and port
  Future<bool> connect(String ipAddress, int port) async {
    if (isConnected) {
      await disconnect();
    }

    try {
      _updateStatus(ConnectionStatus.connecting);

      final uri = Uri.parse('ws://$ipAddress:$port');
      _channel = WebSocketChannel.connect(uri);

      // Listen for connection establishment
      await _channel!.ready;

      // Listen for incoming messages
      _channel!.stream.listen(
        (message) {
          _messageController.add(message.toString());
        },
        onError: (error) {
          print('WebSocket error: $error');
          _updateStatus(ConnectionStatus.error);
          disconnect();
        },
        onDone: () {
          _updateStatus(ConnectionStatus.disconnected);
        },
      );

      _updateStatus(ConnectionStatus.connected);

      // Send init command
      await sendCommand(RobotCommand.init);

      return true;
    } catch (e) {
      print('Connection error: $e');
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }

  /// Disconnect from the robot
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _updateStatus(ConnectionStatus.disconnected);
  }

  /// Send a command to the robot
  Future<void> sendCommand(RobotCommand command) async {
    if (!isConnected) {
      print('Cannot send command: not connected');
      return;
    }

    try {
      _channel?.sink.add(command.commandString);
      print('Sent command: ${command.commandString}');
    } catch (e) {
      print('Error sending command: $e');
    }
  }

  /// Update connection status and notify listeners
  void _updateStatus(ConnectionStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _statusController.close();
    _messageController.close();
  }
}
