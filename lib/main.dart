import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/preset.dart';
import 'package:ueberboese_app/pages/home_page.dart';
import 'package:ueberboese_app/services/speaker_storage_service.dart';
import 'package:ueberboese_app/services/config_storage_service.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = MyAppState();
  await appState.initialize();

  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {

  final MyAppState appState;

  const MyApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: appState,
      child: MaterialApp(
        title: 'Überböse App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.system,
        builder: (context, child) {
          // Configure system navigation bar based on theme brightness
          final brightness = Theme.of(context).brightness;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              systemNavigationBarColor: brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              systemNavigationBarIconBrightness: brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
            ),
            child: child!,
          );
        },
        home: const HomePage(),
      ),
    );
  }
}

class _PresetCacheEntry {
  final List<Preset> presets;
  final DateTime timestamp;

  _PresetCacheEntry({
    required this.presets,
    required this.timestamp,
  });

  bool get isStale {
    return DateTime.now().difference(timestamp) > const Duration(seconds: 30);
  }
}

class MyAppState extends ChangeNotifier {
  final SpeakerStorageService _storageService = SpeakerStorageService();
  final ConfigStorageService _configStorageService = ConfigStorageService();
  final SpeakerApiService _speakerApiService = SpeakerApiService();

  List<Speaker> speakers = [];
  AppConfig config = const AppConfig();

  // Preset cache - maps speaker IP to cached preset list
  final Map<String, _PresetCacheEntry> _presetCache = {};

  Future<void> initialize() async {
    await Future.wait([
      initializeSpeakers(),
      initializeConfig(),
    ]);
    notifyListeners();
  }

  Future<void> initializeSpeakers() async {
    speakers = await _storageService.loadSpeakers();
  }

  Future<void> initializeConfig() async {
    config = await _configStorageService.loadConfig();
  }

  void addSpeaker(Speaker speaker) {
    speakers.add(speaker);
    _storageService.saveSpeakers(speakers);
    notifyListeners();
  }

  void removeSpeaker(Speaker speaker) {
    speakers.remove(speaker);
    _storageService.saveSpeakers(speakers);
    notifyListeners();
  }

  void updateSpeaker(Speaker updatedSpeaker) {
    final index = speakers.indexWhere((s) => s.id == updatedSpeaker.id);
    if (index != -1) {
      speakers[index] = updatedSpeaker;
      _storageService.saveSpeakers(speakers);
      notifyListeners();
    }
  }

  void updateConfig(AppConfig newConfig) {
    config = newConfig;
    _configStorageService.saveConfig(config);
    notifyListeners();
  }

  /// Get presets for a speaker, using cache if available and fresh
  Future<List<Preset>> getPresets(String speakerIp) async {
    // Check if we have a fresh cache entry
    final cacheEntry = _presetCache[speakerIp];
    if (cacheEntry != null && !cacheEntry.isStale) {
      return cacheEntry.presets;
    }

    // Fetch fresh data from API
    final presets = await _speakerApiService.getPresets(speakerIp);

    // Update cache
    _presetCache[speakerIp] = _PresetCacheEntry(
      presets: presets,
      timestamp: DateTime.now(),
    );

    return presets;
  }

  /// Invalidate the preset cache for a specific speaker
  /// Call this after creating, updating, or deleting a preset
  void invalidatePresetsCache(String speakerIp) {
    _presetCache.remove(speakerIp);
    notifyListeners();
  }

  /// Get a specific preset by ID for a speaker
  /// Returns null if the preset is not found
  Preset? getPresetById(String speakerIp, String presetId) {
    final cacheEntry = _presetCache[speakerIp];
    if (cacheEntry == null || cacheEntry.isStale) {
      return null;
    }

    try {
      return cacheEntry.presets.firstWhere((p) => p.id == presetId);
    } catch (e) {
      return null;
    }
  }
}
