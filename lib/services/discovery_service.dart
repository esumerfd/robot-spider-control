import 'dart:async';
import '../models/robot_device.dart';

/// Abstract interface for discovering robot devices on the network or nearby
abstract class DiscoveryService {
  /// Discover the robot device
  ///
  /// Returns null if not found within the timeout period.
  /// For WiFi: searches via mDNS
  /// For Bluetooth: scans for nearby devices by name
  Future<RobotDevice?> discoverRobot({Duration timeout});

  /// Stream that continuously searches for the robot
  ///
  /// Emits null when not found, device when found.
  /// Repeats search at the specified interval.
  Stream<RobotDevice?> watchForRobot({Duration interval});
}
