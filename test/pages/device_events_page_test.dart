import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/models/device_event.dart';
import 'package:ueberboese_app/pages/device_events_page.dart';
import 'package:ueberboese_app/services/management_api_service.dart';

import 'device_events_page_test.mocks.dart';

@GenerateMocks([ManagementApiService])
void main() {
  group('DeviceEventsPage', () {
    late MockManagementApiService mockApiService;
    late MyAppState mockAppState;
    const testSpeaker = Speaker(
      id: '1',
      name: 'Test Speaker',
      emoji: '🔊',
      ipAddress: '192.168.1.100',
      type: 'SoundTouch 10',
      deviceId: 'device-123',
    );

    const testConfig = AppConfig(
      apiUrl: 'http://localhost:3000',
      accountId: 'test-account',
      mgmtUsername: 'testuser',
      mgmtPassword: 'testpass',
    );

    setUp(() {
      mockApiService = MockManagementApiService();
      mockAppState = MyAppState();
      mockAppState.updateConfig(testConfig);
    });

    Widget createWidgetUnderTest() {
      return ChangeNotifierProvider<MyAppState>.value(
        value: mockAppState,
        child: MaterialApp(
          home: DeviceEventsPage(
            speaker: testSpeaker,
            apiService: mockApiService,
          ),
        ),
      );
    }

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => <DeviceEvent>[],
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays "No events found" when list is empty', (WidgetTester tester) async {
      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => <DeviceEvent>[],
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('No events found'), findsOneWidget);
    });

    testWidgets('displays events list when data is loaded', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          type: 'volume-changed',
        ),
        DeviceEvent(
          data: {'playState': 'PLAY_STATE'},
          monoTime: 12346,
          time: DateTime.now().subtract(const Duration(hours: 2)),
          type: 'play-state-changed',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('volume-changed'), findsOneWidget);
      expect(find.text('play-state-changed'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('displays error message and retry button on error', (WidgetTester tester) async {
      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => throw Exception('Failed to fetch device events: HTTP 500'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load events'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('retry button reloads events', (WidgetTester tester) async {
      // First call fails
      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => throw Exception('Failed to fetch device events: HTTP 500'),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Failed to load events'), findsOneWidget);

      // Second call succeeds
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'volume-changed',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('volume-changed'), findsOneWidget);
      expect(find.text('Failed to load events'), findsNothing);
    });

    testWidgets('displays speaker emoji and name in app bar and Device Events title on page', (WidgetTester tester) async {
      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => <DeviceEvent>[],
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('🔊'), findsOneWidget);
      expect(find.text('Test Speaker'), findsOneWidget);
      expect(find.text('Device Events'), findsOneWidget);
    });

    testWidgets('calls fetchDeviceEvents with correct parameters', (WidgetTester tester) async {
      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => <DeviceEvent>[],
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      verify(mockApiService.fetchDeviceEvents(
        'http://localhost:3000',
        'device-123',
        'testuser',
        'testpass',
      )).called(1);
    });

    testWidgets('displays volume icon for volume events', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'volume-changed',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('displays play icon for playback events', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {'playState': 'PLAY_STATE'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'play-state-changed',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('displays source icon for source events', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {'source': 'SPOTIFY'},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'source-state-changed',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.input), findsOneWidget);
    });

    testWidgets('displays settings icon for system events', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'system-state-changed',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('displays default icon for unknown events', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'unknown-event-type',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('formats timestamp as "Just now" for recent events', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now().subtract(const Duration(seconds: 30)),
          type: 'volume-changed',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('formats timestamp as minutes ago', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          type: 'volume-changed',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('5 minutes ago'), findsOneWidget);
    });

    testWidgets('displays event data summary', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {'volume': 50},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'volume-changed',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Volume: 50'), findsOneWidget);
    });

    testWidgets('displays "No additional data" for empty event data', (WidgetTester tester) async {
      final testEvents = [
        DeviceEvent(
          data: {},
          monoTime: 12345,
          time: DateTime.now(),
          type: 'unknown-event',
        ),
      ];

      when(mockApiService.fetchDeviceEvents(any, any, any, any)).thenAnswer(
        (_) async => testEvents,
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('No additional data'), findsOneWidget);
    });
  });
}
