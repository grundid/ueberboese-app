import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/pages/configuration_page.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';
import 'package:ueberboese_app/widgets/envswitch_log_view.dart';

class SpeakerDoctorPage extends StatefulWidget {
  final Speaker speaker;
  final SpeakerSetupService? setupService;

  const SpeakerDoctorPage({
    super.key,
    required this.speaker,
    this.setupService,
  });

  @override
  State<SpeakerDoctorPage> createState() => _SpeakerDoctorPageState();
}

class _SpeakerDoctorPageState extends State<SpeakerDoctorPage> {
  late final SpeakerSetupService _service;

  bool _loading = true;
  String? _error;
  Map<String, String>? _config;
  List<String>? _envswitchLog;

  @override
  void initState() {
    super.initState();
    _service = widget.setupService ??
        SpeakerSetupService(envswitchDelay: Duration.zero);
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw =
          await _service.getSystemConfiguration(widget.speaker.ipAddress);
      if (!mounted) return;
      setState(() {
        _config = SpeakerSetupService.parseSystemConfiguration(raw);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onConnectToUeberboese() async {
    final apiUrl = context.read<MyAppState>().config.apiUrl;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Configuring speaker…'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final log = await _service.configureEnvswitch(
        apiUrl,
        speakerIp: widget.speaker.ipAddress,
      );
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _envswitchLog = log);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Configuration failed'),
          content: Text(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final apiUrl = context.watch<MyAppState>().config.apiUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('Doctor — ${widget.speaker.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('System Configuration',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildConfigSection(theme),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildConnectSection(context, theme, apiUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Failed to load configuration:',
              style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 4),
          Text(_error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loadConfig,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    }
    if (_config == null || _config!.isEmpty) {
      return const Text('No configuration data returned.');
    }

    return Table(
      border: TableBorder.all(
        color: theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: _config!.entries.map((entry) {
        return TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(entry.key,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SelectableText(entry.value,
                  style: theme.textTheme.bodySmall),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildConnectSection(
      BuildContext context, ThemeData theme, String apiUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Connect to Überböse-API', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (apiUrl.isEmpty) ...[
                      Text(
                        'No API URL configured.',
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: theme.colorScheme.onErrorContainer,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                              builder: (context) => const ConfigurationPage()),
                        ),
                        child: const Text('Open Settings to configure it'),
                      ),
                    ] else ...[
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 13),
                          children: [
                            const TextSpan(text: 'API URL: '),
                            TextSpan(
                              text: apiUrl,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can change this in Settings.',
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will reconfigure the speaker to use the URL above '
                        'and reboot it. Only proceed if you are sure.',
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                            fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: apiUrl.isNotEmpty ? _onConnectToUeberboese : null,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('Connect speaker to Überböse-API'),
        ),
        if (_envswitchLog != null) ...[
          const SizedBox(height: 16),
          EnvswitchLogView(log: _envswitchLog!),
        ],
      ],
    );
  }
}
