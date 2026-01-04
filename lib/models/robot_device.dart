/// Represents a discovered hexapod robot device on the network
class RobotDevice {
  final String name;
  final String ipAddress;
  final int port;
  final DateTime discoveredAt;

  RobotDevice({
    required this.name,
    required this.ipAddress,
    required this.port,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RobotDevice &&
        other.ipAddress == ipAddress &&
        other.port == port;
  }

  @override
  int get hashCode => ipAddress.hashCode ^ port.hashCode;

  @override
  String toString() => 'RobotDevice($name, $ipAddress:$port)';

  /// Create a RobotDevice from manual IP entry
  factory RobotDevice.manual({
    required String ipAddress,
    required int port,
  }) {
    return RobotDevice(
      name: 'Manual Connection',
      ipAddress: ipAddress,
      port: port,
    );
  }
}
