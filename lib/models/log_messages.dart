import 'robot_log_message.dart';

/// A rolling log buffer that maintains a fixed-size list of messages
/// using a circular buffer algorithm
class LogMessages {
  final int _maxSize;
  final List<RobotLogMessage?> _buffer;
  int _head = 0; // Next write position
  int _count = 0; // Number of messages currently stored

  LogMessages({int maxSize = 50})
      : _maxSize = maxSize,
        _buffer = List.filled(maxSize, null, growable: false);

  /// Add a message to the rolling log
  void add(RobotLogMessage message) {
    _buffer[_head] = message;
    _head = (_head + 1) % _maxSize;

    if (_count < _maxSize) {
      _count++;
    }
  }

  /// Add an info message
  void info(String message) {
    add(RobotLogMessage.info(message));
  }

  /// Add a success message
  void success(String message) {
    add(RobotLogMessage.success(message));
  }

  /// Add an error message
  void error(String message) {
    add(RobotLogMessage.error(message));
  }

  /// Get all messages in chronological order (oldest to newest)
  List<RobotLogMessage> getAll() {
    if (_count == 0) {
      return [];
    }

    final result = <RobotLogMessage>[];

    if (_count < _maxSize) {
      // Buffer not full yet, messages are from 0 to _count-1
      for (int i = 0; i < _count; i++) {
        final message = _buffer[i];
        if (message != null) {
          result.add(message);
        }
      }
    } else {
      // Buffer is full, read from _head (oldest) to end, then from 0 to _head-1
      for (int i = 0; i < _maxSize; i++) {
        final index = (_head + i) % _maxSize;
        final message = _buffer[index];
        if (message != null) {
          result.add(message);
        }
      }
    }

    return result;
  }

  /// Clear all messages
  void clear() {
    for (int i = 0; i < _maxSize; i++) {
      _buffer[i] = null;
    }
    _head = 0;
    _count = 0;
  }

  /// Number of messages currently stored
  int get length => _count;

  /// Whether the log is empty
  bool get isEmpty => _count == 0;

  /// Whether the log is full
  bool get isFull => _count == _maxSize;

  @override
  String toString() {
    return 'LogMessages(size: $_count/$_maxSize, head: $_head)';
  }
}
