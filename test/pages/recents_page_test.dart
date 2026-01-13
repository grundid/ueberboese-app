import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/recent.dart';
import 'package:ueberboese_app/pages/recents_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

import 'recents_page_test.mocks.dart';

@GenerateMocks([SpeakerApiService])
void main() {
  group('RecentsPage', () {
    late MockSpeakerApiService mockApiService;
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    setUp(() {
      mockApiService = MockSpeakerApiService();
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => <Recent>[],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays "No recent items" when list is empty', (WidgetTester tester) async {
      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => <Recent>[],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No recent items'), findsOneWidget);
    });

    testWidgets('displays recents list when data is loaded', (WidgetTester tester) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768304677,
          id: '4',
          itemName: 'Komplett Entspannt',
          source: 'SPOTIFY',
          location: '/playback/container/c3BvdGlmeTpwbGF5bGlzdDoybjZXMnA1QzBNQUQ5YTR6NXhUVDdu',
          type: 'tracklisturl',
          isPresetable: true,
          sourceAccount: 'z5zt8py3wuxytbza4cxa431ge',
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => testRecents,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Radio TEDDY'), findsOneWidget);
      expect(find.text('Komplett Entspannt'), findsOneWidget);
      expect(find.text('TUNEIN'), findsOneWidget);
      expect(find.text('SPOTIFY'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('displays error message and retry button on error', (WidgetTester tester) async {
      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => throw Exception('Failed to fetch recents: HTTP 500'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load recents'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('retry button reloads recents', (WidgetTester tester) async {
      // First call fails
      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => throw Exception('Failed to fetch recents: HTTP 500'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load recents'), findsOneWidget);

      // Second call succeeds
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => testRecents,
      );

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Radio TEDDY'), findsOneWidget);
      expect(find.text('Failed to load recents'), findsNothing);
    });

    testWidgets('displays speaker emoji and Recent in app bar', (WidgetTester tester) async {
      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => <Recent>[],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('🔊'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
    });

    testWidgets('calls getRecents with correct IP address', (WidgetTester tester) async {
      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => <Recent>[],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      verify(mockApiService.getRecents('192.168.1.100')).called(1);
    });

    testWidgets('displays containerArt when available', (WidgetTester tester) async {
      final testRecents = [
        const Recent(
          deviceId: '44EAD8A17CC7',
          utcTime: 1768323670,
          id: '1',
          itemName: 'Radio TEDDY',
          containerArt: 'http://cdn.example.com/logo.png',
          source: 'TUNEIN',
          location: '/v1/playback/station/s80044',
          type: 'stationurl',
          isPresetable: true,
        ),
      ];

      when(mockApiService.getRecents(any)).thenAnswer(
        (_) async => testRecents,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecentsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
