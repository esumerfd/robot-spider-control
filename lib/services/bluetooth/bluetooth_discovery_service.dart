import 'dart:async';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../discovery_service.dart';
import '../../models/robot_device.dart';
import '../../config/connection_config.dart';
import 'bluetooth_permission_handler.dart';

/// Service for discovering hexapod robots via Bluetooth Classic
class BluetoothDiscoveryService implements DiscoveryService {
  /// Discover the robot by Bluetooth device name
  ///
  /// First checks paired (bonded) devices for fast discovery.
  /// If not found in paired devices, starts a full Bluetooth discovery scan.
  ///
  /// Returns null if:
  /// - Bluetooth is not enabled
  /// - Permissions are denied
  /// - No matching device found within timeout
  @override
  Future<RobotDevice?> discoverRobot({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      // Check if Bluetooth is enabled
      final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled == null || !isEnabled) {
        print('Bluetooth is not enabled');
        return null;
      }

      // Request permissions
      final hasPermissions = await BluetoothPermissionHandler.requestPermissions();
      if (!hasPermissions) {
        print('Bluetooth permissions not granted');
        return null;
      }

      // First, check paired devices (fast path)
      print('Checking paired Bluetooth devices...');
      final pairedDevice = await _findInPairedDevices();
      if (pairedDevice != null) {
        print('Found robot in paired devices: ${pairedDevice.name}');
        return pairedDevice;
      }

      // Not found in paired devices, start discovery scan
      print('Starting Bluetooth discovery scan...');
      final discoveredDevice = await _discoverNewDevices(timeout);
      if (discoveredDevice != null) {
        print('Found robot via discovery: ${discoveredDevice.name}');
        return discoveredDevice;
      }

      print('Robot not found via Bluetooth');
      return null;
    } catch (e) {
      print('Bluetooth discovery error: $e');
      return null;
    }
  }

  /// Check paired devices for the robot
  Future<RobotDevice?> _findInPairedDevices() async {
    try {
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();

      for (final device in bondedDevices) {
        final deviceName = device.name ?? '';
        if (deviceName.contains(ConnectionConfig.bluetoothDeviceName)) {
          return RobotDevice(
            name: deviceName,
            ipAddress: device.address, // MAC address stored as ipAddress
            port: 0, // Port not used for Bluetooth
          );
        }
      }
    } catch (e) {
      print('Error checking paired devices: $e');
    }

    return null;
  }

  /// Perform Bluetooth discovery scan for new devices
  Future<RobotDevice?> _discoverNewDevices(Duration timeout) async {
    try {
      final completer = Completer<RobotDevice?>();
      StreamSubscription? subscription;

      // Start discovery
      subscription = FlutterBluetoothSerial.instance.startDiscovery().listen(
        (result) {
          final deviceName = result.device.name ?? '';
          if (deviceName.contains(ConnectionConfig.bluetoothDeviceName)) {
            // Found matching device
            final device = RobotDevice(
              name: deviceName,
              ipAddress: result.device.address,
              port: 0,
            );

            if (!completer.isCompleted) {
              completer.complete(device);
              subscription?.cancel();
            }
          }
        },
        onError: (error) {
          print('Discovery error: $error');
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      );

      // Set timeout
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          subscription?.cancel();
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      print('Error during Bluetooth discovery: $e');
      return null;
    }
  }

  @override
  Stream<RobotDevice?> watchForRobot({
    Duration interval = const Duration(seconds: 3),
  }) async* {
    while (true) {
      final device = await discoverRobot();
      yield device;
      await Future.delayed(interval);
    }
  }
}
