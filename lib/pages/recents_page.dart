import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/recent.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

class RecentsPage extends StatefulWidget {
  final Speaker speaker;
  final SpeakerApiService? apiService;

  const RecentsPage({
    super.key,
    required this.speaker,
    this.apiService,
  });

  @override
  State<RecentsPage> createState() => _RecentsPageState();
}

class _RecentsPageState extends State<RecentsPage> {
  late final SpeakerApiService _speakerApiService;
  Future<List<Recent>>? _recentsFuture;

  @override
  void initState() {
    super.initState();
    _speakerApiService = widget.apiService ?? SpeakerApiService();
    _loadRecents();
  }

  void _loadRecents() {
    setState(() {
      _recentsFuture = _speakerApiService.getRecents(widget.speaker.ipAddress);
    });
  }

  void _retryLoad() {
    _loadRecents();
  }

  String _formatTimestamp(int utcTime) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(utcTime * 1000);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'SPOTIFY':
        return Icons.music_note;
      case 'TUNEIN':
        return Icons.radio;
      case 'LOCAL_INTERNET_RADIO':
        return Icons.podcasts;
      default:
        return Icons.album;
    }
  }

  Color _getSourceColor(BuildContext context, String source) {
    final theme = Theme.of(context);
    switch (source) {
      case 'SPOTIFY':
        return Colors.green;
      case 'TUNEIN':
        return Colors.blue;
      case 'LOCAL_INTERNET_RADIO':
        return Colors.orange;
      default:
        return theme.colorScheme.primary;
    }
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
            const Text('Recent'),
          ],
        ),
      ),
      body: FutureBuilder<List<Recent>>(
        future: _recentsFuture,
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
                    'Failed to load recents',
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

          final recents = snapshot.data ?? [];

          if (recents.isEmpty) {
            return const Center(
              child: Text('No recent items'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recents.length,
            itemBuilder: (context, index) {
              final recent = recents[index];
              final sourceColor = _getSourceColor(context, recent.source);
              final sourceIcon = _getSourceIcon(recent.source);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  leading: recent.containerArt != null &&
                          recent.containerArt!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            recent.containerArt!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 56,
                                height: 56,
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  sourceIcon,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            sourceIcon,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                  title: Text(
                    recent.itemName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            sourceIcon,
                            size: 14,
                            color: sourceColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recent.source,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: sourceColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTimestamp(recent.utcTime),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
