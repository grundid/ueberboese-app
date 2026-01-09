import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/speaker.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MyAppState', () {
    test('addSpeaker adds speaker to list', () async {
      final appState = MyAppState();
      await appState.initializeSpeakers();
      final initialCount = appState.speakers.length;

      const newSpeaker = Speaker(
        id: 'test-1',
        name: 'Test Speaker',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
        type: 'SoundTouch 10',
        deviceId: 'device-test',
      );

      appState.addSpeaker(newSpeaker);

      expect(appState.speakers.length, initialCount + 1);
      expect(appState.speakers.last, newSpeaker);
    });

    test('addSpeaker notifies listeners', () async {
      final appState = MyAppState();
      await appState.initializeSpeakers();
      var notified = false;

      appState.addListener(() {
        notified = true;
      });

      const newSpeaker = Speaker(
        id: 'test-1',
        name: 'Test Speaker',
        emoji: '🎵',
        ipAddress: '192.168.1.200',
        type: 'SoundTouch 10',
        deviceId: 'device-test',
      );

      appState.addSpeaker(newSpeaker);

      expect(notified, true);
    });
  });

  group('MyApp', () {
    testWidgets('builds correctly in light mode',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(MyApp(appState: appState));
      await tester.pumpAndSettle();

      // Verify that the app builds without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('builds correctly in dark mode',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final appState = MyAppState();
      await appState.initialize();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: MyApp(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that the app builds without errors in dark mode
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
