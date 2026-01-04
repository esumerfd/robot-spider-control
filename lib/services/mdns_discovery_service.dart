import 'dart:async';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import '../models/robot_device.dart';

/// Service for discovering hexapod robots on the local network using mDNS
class MdnsDiscoveryService {
  static const String robotHostname = 'robot-spider.local';
  static const int defaultPort = 8080; // Default WebSocket port

  /// Discovers the hexapod robot on the local network
  /// Returns null if not found within the timeout period
  Future<RobotDevice?> discoverRobot({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final client = MDnsClient();
    RobotDevice? discoveredDevice;

    try {
      // Start the mDNS client
      await client.start();

      // Look up the robot hostname
      await for (final PtrResourceRecord ptr
          in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(robotHostname),
      )) {
        // Got a response, now resolve the IP address
        await for (final IPAddressResourceRecord ip
            in client.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(ptr.domainName),
        )) {
          if (ip.address.type == InternetAddressType.IPv4) {
            discoveredDevice = RobotDevice(
              name: robotHostname,
              ipAddress: ip.address.address,
              port: defaultPort,
            );
            break;
          }
        }
        if (discoveredDevice != null) break;
      }

      // If no PTR record found, try direct A record lookup
      if (discoveredDevice == null) {
        await for (final IPAddressResourceRecord record
            in client.lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4(robotHostname),
        ).timeout(timeout)) {
          if (record.address.type == InternetAddressType.IPv4) {
            discoveredDevice = RobotDevice(
              name: robotHostname,
              ipAddress: record.address.address,
              port: defaultPort,
            );
            break;
          }
        }
      }
    } on TimeoutException {
      // Discovery timed out
      return null;
    } catch (e) {
      print('mDNS discovery error: $e');
      return null;
    } finally {
      client.stop();
    }

    return discoveredDevice;
  }

  /// Stream that continuously searches for the robot
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
