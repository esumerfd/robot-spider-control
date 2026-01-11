/// Types of log messages from the robot
enum RobotLogType {
  info,
  success,
  error,
}

/// A log message from the robot with timestamp and type
class RobotLogMessage {
  final DateTime timestamp;
  final String message;
  final RobotLogType type;

  RobotLogMessage({
    DateTime? timestamp,
    required this.message,
    required this.type,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a log message from a robot response
  /// Parses "OK:" prefix as success, "ERROR:" as error, otherwise info
  factory RobotLogMessage.fromResponse(String response) {
    final trimmed = response.trim();

    if (trimmed.startsWith('OK:')) {
      final command = trimmed.substring(3).trim();
      return RobotLogMessage(
        message: command.isEmpty ? 'Command acknowledged' : 'OK: $command',
        type: RobotLogType.success,
      );
    } else if (trimmed.startsWith('ERROR:')) {
      final errorMsg = trimmed.substring(6).trim();
      return RobotLogMessage(
        message: errorMsg.isEmpty ? 'Unknown error' : errorMsg,
        type: RobotLogType.error,
      );
    } else {
      return RobotLogMessage(
        message: trimmed.isEmpty ? 'Empty response' : trimmed,
        type: RobotLogType.info,
      );
    }
  }

  /// Create an info log message
  factory RobotLogMessage.info(String message) {
    return RobotLogMessage(
      message: message,
      type: RobotLogType.info,
    );
  }

  /// Create a success log message
  factory RobotLogMessage.success(String message) {
    return RobotLogMessage(
      message: message,
      type: RobotLogType.success,
    );
  }

  /// Create an error log message
  factory RobotLogMessage.error(String message) {
    return RobotLogMessage(
      message: message,
      type: RobotLogType.error,
    );
  }

  @override
  String toString() {
    return 'RobotLogMessage(${timestamp.toString().substring(11, 19)}, $type, $message)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RobotLogMessage &&
        other.timestamp == timestamp &&
        other.message == message &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(timestamp, message, type);
}
