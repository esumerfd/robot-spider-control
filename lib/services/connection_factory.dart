import 'connection_service.dart';
import 'discovery_service.dart';
import 'websocket_service.dart';
import 'mdns_discovery_service.dart';
// Bluetooth imports will be added in Phase 2:
// import 'bluetooth/bluetooth_connection_service.dart';
// import 'bluetooth/bluetooth_discovery_service.dart';

/// Connection type enum for selecting transport mechanism
enum ConnectionType {
  /// WiFi connection via WebSocket
  wifi,

  /// Bluetooth Classic connection via Serial Port Profile
  bluetooth,
}

/// Factory for creating connection and discovery services based on connection type
class ConnectionFactory {
  /// Create a connection service for the specified connection type
  static ConnectionService createConnectionService(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
        return WebSocketService();
      case ConnectionType.bluetooth:
        // TODO: Phase 2 - Implement Bluetooth connection service
        throw UnimplementedError(
          'Bluetooth connection service will be implemented in Phase 2',
        );
        // return BluetoothConnectionService();
    }
  }

  /// Create a discovery service for the specified connection type
  static DiscoveryService createDiscoveryService(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
        return MdnsDiscoveryService();
      case ConnectionType.bluetooth:
        // TODO: Phase 2 - Implement Bluetooth discovery service
        throw UnimplementedError(
          'Bluetooth discovery service will be implemented in Phase 2',
        );
        // return BluetoothDiscoveryService();
    }
  }
}
