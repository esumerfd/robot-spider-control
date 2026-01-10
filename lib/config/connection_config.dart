import '../services/connection_factory.dart';

/// Configuration for robot connection settings
class ConnectionConfig {
  /// Default connection type for the robot
  ///
  /// Set to ConnectionType.wifi for WiFi/WebSocket
  /// Set to ConnectionType.bluetooth for Bluetooth Classic
  static const ConnectionType defaultConnectionType = ConnectionType.bluetooth;

  /// Robot name for Bluetooth discovery
  ///
  /// The app will search for devices containing this name
  static const String bluetoothDeviceName = 'robot-spider';

  /// WiFi settings (used when defaultConnectionType == wifi)
  static const String wifiHostname = 'robot-spider.local';
  static const int wifiPort = 8080;
}
