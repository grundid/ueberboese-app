import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/now_playing.dart';
import 'package:ueberboese_app/widgets/emoji_selector.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';
import 'package:ueberboese_app/services/management_api_service.dart';
import 'package:ueberboese_app/pages/speaker_detail_page.dart';
import 'package:ueberboese_app/pages/add_speaker_page.dart';
import 'package:ueberboese_app/pages/configuration_page.dart';

class SpeakerListPage extends StatefulWidget {
  final SpeakerApiService? apiService;

  const SpeakerListPage({super.key, this.apiService});

  @override
  State<SpeakerListPage> createState() => _SpeakerListPageState();
}

class _SpeakerListPageState extends State<SpeakerListPage> with SingleTickerProviderStateMixin {
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  late final SpeakerApiService _speakerApiService;
  final _managementApiService = ManagementApiService();

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _speakerApiService = widget.apiService ?? SpeakerApiService();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _closeFab() {
    if (_isFabExpanded) {
      setState(() {
        _isFabExpanded = false;
        _animationController.reverse();
      });
    }
  }

  String _getNextAvailableEmoji(List<Speaker> speakers) {
    final usedEmojis = speakers.map((s) => s.emoji).toSet();

    for (final emoji in EmojiSelector.availableEmojis) {
      if (!usedEmojis.contains(emoji)) {
        return emoji;
      }
    }

    return EmojiSelector.availableEmojis.first;
  }

  void _startPolling() {
    // Initial poll - use addPostFrameCallback to avoid notifying during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appState = context.read<MyAppState>();
      appState.pollAllSpeakersNowPlaying();
    });

    // Set up periodic polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) return;
      final appState = context.read<MyAppState>();
      appState.pollAllSpeakersNowPlaying();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  String? _getFullArtworkUrl(Speaker speaker, NowPlaying? nowPlaying) {
    if (nowPlaying?.art == null || nowPlaying!.art!.isEmpty) return null;
    final art = nowPlaying.art!;
    if (art.startsWith('http')) return art;
    return 'http://${speaker.ipAddress}:8090$art';
  }

  Widget _buildSpeakerListTile(
    BuildContext context,
    Speaker speaker,
    ThemeData cardTheme,
    bool isConnected,
    bool isPlaying,
    bool hasArtwork,
  ) {
    final listTile = ListTile(
      leading: Text(
        speaker.emoji,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      title: Text(
        speaker.name,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: hasArtwork
            ? cardTheme.colorScheme.surface
            : !isConnected
              ? cardTheme.colorScheme.onErrorContainer
              : null,
        ),
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              speaker.type,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: hasArtwork
                    ? cardTheme.colorScheme.surface
                    : !isConnected
                      ? cardTheme.colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          if (!isConnected) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.wifi_off,
              size: 16,
              color: cardTheme.colorScheme.onErrorContainer,
            ),
          ],
        ],
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: hasArtwork
            ? cardTheme.colorScheme.surface
            : Theme.of(context).colorScheme.primary,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => SpeakerDetailPage(speaker: speaker),
          ),
        );
      },
    );

    // Only wrap in Hero when there's no artwork
    // (to avoid conflict with album art hero)
    if (hasArtwork) {
      return listTile;
    }

    return Hero(
      tag: 'speaker-info-${speaker.id}',
      child: Material(
        color: Colors.transparent,
        child: listTile,
      ),
    );
  }

  Future<void> _addAllSpeakersFromAccount() async {
    _closeFab();

    final appState = context.read<MyAppState>();
    final config = appState.config;

    // Validate configuration
    if (config.apiUrl.isEmpty) {
      _showConfigurationErrorDialog(
        'API URL not configured',
        'Please configure the Überböse API URL in the settings to use this feature.',
      );
      return;
    }

    if (config.accountId.isEmpty) {
      _showConfigurationErrorDialog(
        'Account ID not configured',
        'Please configure your Account ID in the settings to use this feature.',
      );
      return;
    }

    if (config.mgmtUsername.isEmpty) {
      _showConfigurationErrorDialog(
        'Management username not configured',
        'Please configure the management username in the settings to use this feature.',
      );
      return;
    }

    if (config.mgmtPassword.isEmpty) {
      _showConfigurationErrorDialog(
        'Management password not configured',
        'Please configure the management password in the settings to use this feature.',
      );
      return;
    }

    // Check if running on web
    if (kIsWeb) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Web Platform Not Supported'),
          content: const Text(
            'Adding speakers from account is not supported in the web browser due to CORS restrictions.\n\n'
            'Please use the native app instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Fetching speakers from account...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Fetch IP addresses from management API
      final ipAddresses = await _managementApiService.fetchAccountSpeakers(
        config.apiUrl,
        config.accountId,
        config.mgmtUsername,
        config.mgmtPassword,
      );

      if (!mounted) return;

      if (ipAddresses.isEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No speakers found in account'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Process each IP address
      int addedCount = 0;
      int existingCount = 0;
      int failedCount = 0;

      for (final ipAddress in ipAddresses) {
        // Check if speaker already exists
        final existingSpeaker = appState.speakers.cast<Speaker?>().firstWhere(
          (speaker) => speaker?.ipAddress == ipAddress,
          orElse: () => null,
        );

        if (existingSpeaker != null) {
          existingCount++;
          continue;
        }

        // Try to fetch speaker info and add
        try {
          final emoji = _getNextAvailableEmoji(appState.speakers);
          final newSpeaker = await _speakerApiService.createSpeakerFromIp(ipAddress, emoji);

          appState.addSpeaker(newSpeaker);
          addedCount++;

          // Small delay to avoid overwhelming the speakers
          await Future<void>.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          failedCount++;
        }
      }

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      // Show summary
      if (addedCount > 0 || existingCount > 0) {
        final parts = <String>[];
        if (addedCount > 0) {
          parts.add('Added $addedCount ${addedCount == 1 ? 'speaker' : 'speakers'}');
        }
        if (existingCount > 0) {
          parts.add('$existingCount already existed');
        }
        if (failedCount > 0) {
          parts.add('$failedCount failed');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parts.join(', ')),
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Failed to Add Speakers'),
            content: Text(
              'Failed to add any speakers from the account. $failedCount ${failedCount == 1 ? 'speaker' : 'speakers'} could not be reached.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: SelectableText(
            'Failed to fetch speakers from account.\n\n${e.toString()}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showConfigurationErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const ConfigurationPage(),
                ),
              );
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final theme = Theme.of(context);

    Widget content;
    if (appState.speakers.isEmpty) {
      content = const Center(
        child: Text('No speakers available'),
      );
    } else {
      content = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.speakers.length,
        itemBuilder: (context, index) {
          final speaker = appState.speakers[index];
          final nowPlaying = appState.getCachedNowPlaying(speaker.ipAddress);
          final isConnected = appState.getSpeakerConnectionStatus(speaker.ipAddress);
          final isPlaying = nowPlaying?.playStatus == 'PLAY_STATE';
          final artworkUrl = _getFullArtworkUrl(speaker, nowPlaying);
          // Show artwork if present, regardless of play status (consistent with detail page)
          final hasArtwork = artworkUrl != null &&
                            artworkUrl.isNotEmpty &&
                            nowPlaying?.artImageStatus == 'IMAGE_PRESENT';
          final cardTheme = Theme.of(context);

          return Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            color: !isConnected ? cardTheme.colorScheme.errorContainer : null,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Background image with overlay (if has artwork)
                if (hasArtwork)
                  Positioned.fill(
                    child: Hero(
                      tag: 'album-art-${speaker.id}',
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            artworkUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(),
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              // Only show the image with overlay if it loaded successfully
                              if (frame == null) {
                                return const SizedBox();
                              }
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  child,
                                  Container(
                                    color: cardTheme.colorScheme.scrim.withValues(alpha: 0.4),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                // Actual content
                // Wrap in Hero when there's no artwork to animate speaker info
                _buildSpeakerListTile(
                  context,
                  speaker,
                  cardTheme,
                  isConnected,
                  isPlaying,
                  hasArtwork,
                ),
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          content,
          if (_isFabExpanded)
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _closeFab,
                  child: Container(
                    color: theme.colorScheme.scrim.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mini FAB 2: Add all from account
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Add all from account',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'add_all_fab',
                      onPressed: _addAllSpeakersFromAccount,
                      tooltip: 'Add all from account',
                      child: const Icon(Icons.cloud_download),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Mini FAB 1: Add by IP
          FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(8),
                      color: theme.colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          'Add by IP',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.small(
                      heroTag: 'add_by_ip_fab',
                      onPressed: () {
                        _closeFab();
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const AddSpeakerPage(),
                          ),
                        );
                      },
                      tooltip: 'Add by IP',
                      child: const Icon(Icons.router),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Main FAB
          RotationTransition(
            turns: _rotationAnimation,
            child: FloatingActionButton(
              onPressed: _toggleFab,
              tooltip: 'Add speaker',
              child: Icon(_isFabExpanded ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
