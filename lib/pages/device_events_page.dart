import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/models/device_event.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/services/management_api_service.dart';
import 'package:ueberboese_app/main.dart';

class DeviceEventsPage extends StatefulWidget {
  final Speaker speaker;
  final ManagementApiService? apiService;

  const DeviceEventsPage({
    super.key,
    required this.speaker,
    this.apiService,
  });

  @override
  State<DeviceEventsPage> createState() => _DeviceEventsPageState();
}

class _DeviceEventsPageState extends State<DeviceEventsPage> {
  late final ManagementApiService _managementApiService;
  Future<List<DeviceEvent>>? _eventsFuture;

  @override
  void initState() {
    super.initState();
    _managementApiService = widget.apiService ?? ManagementApiService();
    _loadEvents();
  }

  void _loadEvents() {
    final appState = context.read<MyAppState>();
    final config = appState.config;

    setState(() {
      _eventsFuture = _managementApiService.fetchDeviceEvents(
        config.apiUrl,
        widget.speaker.deviceId,
        config.mgmtUsername,
        config.mgmtPassword,
      );
    });
  }

  void _retryLoad() {
    _loadEvents();
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(time);
    }
  }

  IconData _getEventIcon(String eventType) {
    if (eventType.contains('volume')) {
      return Icons.volume_up;
    } else if (eventType.contains('play') || eventType.contains('item-started')) {
      return Icons.play_arrow;
    } else if (eventType.contains('source')) {
      return Icons.input;
    } else if (eventType.contains('art')) {
      return Icons.image;
    } else if (eventType.contains('masterdevice') || eventType.contains('system')) {
      return Icons.settings;
    } else {
      return Icons.event;
    }
  }

  String _getEventSummary(DeviceEvent event) {
    final data = event.data;

    if (event.type.contains('volume') && data.containsKey('volume')) {
      return 'Volume: ${data['volume']}';
    } else if (event.type.contains('play-state') && data.containsKey('playState')) {
      return 'Play state: ${data['playState']}';
    } else if (event.type.contains('source') && data.containsKey('source')) {
      return 'Source: ${data['source']}';
    } else if (data.isNotEmpty) {
      // Show first key-value pair as summary
      final firstKey = data.keys.first;
      final firstValue = data[firstKey];
      return '$firstKey: ${firstValue.toString().length > 30 ? '${firstValue.toString().substring(0, 30)}...' : firstValue}';
    }

    return 'No additional data';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.speaker.emoji),
            const SizedBox(width: 8),
            Text(widget.speaker.name),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Device Events',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DeviceEvent>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load events',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SelectableText(
                            snapshot.error.toString(),
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _retryLoad,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return const Center(
                    child: Text('No events found'),
                  );
                }

                return ListView.separated(
                  itemCount: events.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final eventIcon = _getEventIcon(event.type);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          eventIcon,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(
                        event.type,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            _getEventSummary(event),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(event.time),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
