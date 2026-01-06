import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/robot_connection_provider.dart';
import '../models/connection_status.dart';

/// Control screen for operating the hexapod robot
class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robot Control'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<RobotConnectionProvider>(
        builder: (context, provider, child) {
          return provider.isConnected
              ? _buildControlPanel(context, provider)
              : _buildNotConnectedMessage(context);
        },
      ),
    );
  }

  Widget _buildNotConnectedMessage(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Not connected to robot',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please connect from the Setup screen first',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(
    BuildContext context,
    RobotConnectionProvider provider,
  ) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Forward button
              _buildControlButton(
                context: context,
                icon: Icons.arrow_upward,
                label: 'Forward',
                onPressed: () => provider.moveForward(),
              ),
              const SizedBox(height: 16),
              // Left and Right buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    context: context,
                    icon: Icons.arrow_back,
                    label: 'Left',
                    onPressed: () => provider.turnLeft(),
                  ),
                  const SizedBox(width: 24),
                  _buildControlButton(
                    context: context,
                    icon: Icons.arrow_forward,
                    label: 'Right',
                    onPressed: () => provider.turnRight(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Backward button
              _buildControlButton(
                context: context,
                icon: Icons.arrow_downward,
                label: 'Backward',
                onPressed: () => provider.moveBackward(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 100,
      height: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
