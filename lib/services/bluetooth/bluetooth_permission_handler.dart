import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Handler for Bluetooth permissions on Android
class BluetoothPermissionHandler {
  /// Request necessary Bluetooth permissions
  ///
  /// On Android 12+ (SDK 31+), requires:
  /// - BLUETOOTH_SCAN
  /// - BLUETOOTH_CONNECT
  /// - ACCESS_FINE_LOCATION
  ///
  /// On older Android versions, permissions are granted at install time.
  /// On iOS, Bluetooth permissions are handled automatically by the system.
  ///
  /// Returns true if all required permissions are granted.
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Request all necessary permissions
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      // Check if all permissions are granted
      final allGranted = statuses.values.every((status) => status.isGranted);

      if (!allGranted) {
        // Log which permissions were denied
        statuses.forEach((permission, status) {
          if (!status.isGranted) {
            print('Permission denied: $permission (status: $status)');
          }
        });
      }

      return allGranted;
    }

    // iOS handles Bluetooth permissions automatically
    return true;
  }

  /// Check if all required Bluetooth permissions are granted
  ///
  /// Returns true if all permissions are granted, false otherwise.
  static Future<bool> hasPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      return statuses.values.every((status) => status.isGranted);
    }

    // iOS handles automatically
    return true;
  }

  /// Open app settings to allow user to manually grant permissions
  ///
  /// Useful when permissions have been permanently denied.
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
