import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/robot_connection_provider.dart';
import '../models/connection_status.dart';
import '../services/connection_factory.dart';
import '../config/connection_config.dart';

/// Setup screen for discovering and connecting to the hexapod robot
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  bool _showManualEntry = false;

  @override
  void initState() {
    super.initState();
    // Auto-discover only if not already connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<RobotConnectionProvider>();
      if (!provider.isConnected) {
        provider.discoverRobot();
      }
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Connection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<RobotConnectionProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(provider),
                const SizedBox(height: 24),
                _buildDiscoverySection(provider),
                // Only show manual IP entry for WiFi connections
                if (provider.connectionType == ConnectionType.wifi) ...[
                  const SizedBox(height: 24),
                  _buildManualEntrySection(provider),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(RobotConnectionProvider provider) {
    Color statusColor;
    IconData statusIcon;

    switch (provider.connectionStatus) {
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      case ConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
      case ConnectionStatus.error:
        statusColor = Colors.red;
        statusIcon = Icons.error;
      case ConnectionStatus.disconnected:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${provider.connectionStatus.displayText}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Row(
                        children: [
                          Icon(
                            provider.connectionType == ConnectionType.wifi
                                ? Icons.wifi
                                : Icons.bluetooth,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            provider.connectionType == ConnectionType.wifi
                                ? 'WiFi'
                                : 'Bluetooth',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (provider.connectedDevice != null)
                        Text(
                          'Connected to ${provider.connectedDevice!.ipAddress}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverySection(RobotConnectionProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Auto-Discovery',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (provider.isDiscovering)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      provider.connectionType == ConnectionType.wifi
                          ? 'Searching for ${ConnectionConfig.wifiHostname}...'
                          : 'Searching for ${ConnectionConfig.bluetoothDeviceName}...',
                    ),
                  ],
                ),
              )
            else if (provider.discoveredDevice != null)
              _buildDiscoveredDeviceCard(provider)
            else
              Column(
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    provider.connectionType == ConnectionType.wifi
                        ? '${ConnectionConfig.wifiHostname} not found'
                        : '${ConnectionConfig.bluetoothDeviceName} not found',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveredDeviceCard(RobotConnectionProvider provider) {
    final device = provider.discoveredDevice!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      '${device.ipAddress}:${device.port}',
                      style: const TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: provider.isConnected
                    ? () => provider.disconnect()
                    : () => provider.connectToRobot(device),
                icon: Icon(
                  provider.isConnected ? Icons.link_off : Icons.link,
                  size: 18,
                ),
                label: Text(
                  provider.isConnected ? 'Disconnect' : 'Connect',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntrySection(RobotConnectionProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _showManualEntry = !_showManualEntry;
                });
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Manual Connection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Icon(
                    _showManualEntry
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
            ),
            if (_showManualEntry) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  hintText: '192.168.1.100',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '8080',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  final ip = _ipController.text.trim();
                  final port = int.tryParse(_portController.text.trim());
                  if (ip.isNotEmpty && port != null) {
                    provider.connectToManualIp(ip, port);
                  }
                },
                icon: const Icon(Icons.link),
                label: const Text('Connect'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
