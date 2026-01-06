import 'dart:async';
import 'dart:io';
import 'package:multicast_dns/multicast_dns.dart';
import '../models/robot_device.dart';

/// Service for discovering hexapod robots on the local network using mDNS
class MdnsDiscoveryService {
  static const String robotServiceName = 'robot-spider';
  static const String serviceType = '_http._tcp.local';
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

      // Browse for HTTP services (_http._tcp.local.)
      await for (final PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(serviceType),
          )
          .timeout(timeout)) {

        // Check if this is our robot service
        if (ptr.domainName.startsWith(robotServiceName)) {
          print('Found robot service: ${ptr.domainName}');

          // Now look up the service details (SRV record)
          await for (final SrvResourceRecord srv in client
              .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName),
              )
              .timeout(timeout)) {

            final servicePort = srv.port;
            final targetHost = srv.target;

            print('Service target: $targetHost on port $servicePort');

            // Resolve the IP address of the target
            await for (final IPAddressResourceRecord ip in client
                .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(targetHost),
                )
                .timeout(timeout)) {

              if (ip.address.type == InternetAddressType.IPv4) {
                discoveredDevice = RobotDevice(
                  name: ptr.domainName,
                  ipAddress: ip.address.address,
                  port: servicePort,
                );
                print('Resolved to: ${ip.address.address}:$servicePort');
                break;
              }
            }

            if (discoveredDevice != null) break;
          }

          if (discoveredDevice != null) break;
        }
      }

      // Fallback: Try direct hostname resolution (for backwards compatibility)
      if (discoveredDevice == null) {
        print('Service discovery failed, trying direct hostname lookup...');
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
            print('Direct lookup succeeded: ${record.address.address}');
            break;
          }
        }
      }
    } on TimeoutException {
      print('mDNS discovery timed out');
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
