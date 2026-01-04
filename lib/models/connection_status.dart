/// Connection status states for the hexapod robot
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Extension to provide human-readable status messages
extension ConnectionStatusExtension on ConnectionStatus {
  String get displayText {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.error:
        return 'Connection Error';
    }
  }
}
