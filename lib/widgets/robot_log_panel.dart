import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import '../models/robot_log_message.dart';

/// A compact panel displaying robot response logs with auto-scroll
class RobotLogPanel extends StatefulWidget {
  final List<RobotLogMessage> messages;
  final VoidCallback? onClear;
  final double height;
  final bool showTimestamp;

  const RobotLogPanel({
    super.key,
    required this.messages,
    this.onClear,
    this.height = 200,
    this.showTimestamp = true,
  });

  @override
  State<RobotLogPanel> createState() => _RobotLogPanelState();
}

class _RobotLogPanelState extends State<RobotLogPanel> {
  final ScrollController _scrollController = ScrollController();
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _previousMessageCount = widget.messages.length;
  }

  @override
  void didUpdateWidget(RobotLogPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-scroll to bottom when new messages are added
    if (widget.messages.length > _previousMessageCount) {
      _previousMessageCount = widget.messages.length;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  IconData _getIconForType(RobotLogType type) {
    switch (type) {
      case RobotLogType.success:
        return Icons.check_circle;
      case RobotLogType.error:
        return Icons.error;
      case RobotLogType.info:
        return Icons.info;
    }
  }

  Color _getColorForType(RobotLogType type, BuildContext context) {
    switch (type) {
      case RobotLogType.success:
        return Colors.green;
      case RobotLogType.error:
        return Colors.red;
      case RobotLogType.info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.terminal,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Robot Responses',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                if (widget.onClear != null && widget.messages.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Clear logs',
                    onPressed: widget.onClear,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Log list
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: Text(
                      'No responses yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.messages.length,
                    itemBuilder: (context, index) {
                      final message = widget.messages[index];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: Icon(
                          _getIconForType(message.type),
                          size: 16,
                          color: _getColorForType(message.type, context),
                        ),
                        title: Text(
                          message.message,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        subtitle: widget.showTimestamp
                            ? Text(
                                _timeFormat.format(message.timestamp),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
