/// Enum representing commands that can be sent to the hexapod robot
enum RobotCommand {
  init,
  forward,
  backward,
  left,
  right,
}

/// Extension to convert command enum to string for WebSocket transmission
extension RobotCommandExtension on RobotCommand {
  String get commandString {
    switch (this) {
      case RobotCommand.init:
        return 'init';
      case RobotCommand.forward:
        return 'forward';
      case RobotCommand.backward:
        return 'backward';
      case RobotCommand.left:
        return 'left';
      case RobotCommand.right:
        return 'right';
    }
  }
}
