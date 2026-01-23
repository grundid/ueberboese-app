import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/preset.dart';

/// Test version of MyAppState that allows direct preset injection for testing
class TestMyAppState extends MyAppState {
  final Map<String, List<Preset>> testPresets = {};

  @override
  Future<List<Preset>> getPresets(String speakerIp) async {
    return testPresets[speakerIp] ?? [];
  }

  @override
  Preset? getPresetById(String speakerIp, String presetId) {
    final presets = testPresets[speakerIp] ?? [];
    try {
      return presets.firstWhere((p) => p.id == presetId);
    } catch (e) {
      return null;
    }
  }

  /// Helper method to set presets for testing
  void setTestPresets(String speakerIp, List<Preset> presets) {
    testPresets[speakerIp] = presets;
  }
}
