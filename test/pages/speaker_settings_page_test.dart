import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/models/bass.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/pages/speaker_settings_page.dart';
import 'package:ueberboese_app/services/speaker_api_service.dart';

import 'speaker_settings_page_test.mocks.dart';

@GenerateMocks([SpeakerApiService])
void main() {
  const testSpeaker = Speaker(
    id: '1',
    name: 'Test Speaker',
    emoji: '🔊',
    ipAddress: '192.168.1.100',
    type: 'SoundTouch 10',
    deviceId: 'device-123',
  );

  const testBassCapabilities = BassCapabilities(
    bassAvailable: true,
    bassMin: -9,
    bassMax: 0,
    bassDefault: 0,
  );

  const testBass = Bass(targetBass: -5, actualBass: -5);

  const unsupportedBassCapabilities = BassCapabilities(
    bassAvailable: false,
    bassMin: -9,
    bassMax: 0,
    bassDefault: 0,
  );

  group('SpeakerSettingsPage', () {
    late MockSpeakerApiService mockApiService;

    setUp(() {
      mockApiService = MockSpeakerApiService();
      // Default stubs — individual tests can override these.
      when(mockApiService.getLanguage(any)).thenAnswer((_) async => 3);
      when(mockApiService.getBassCapabilities(any))
          .thenAnswer((_) async => testBassCapabilities);
      when(mockApiService.getBass(any)).thenAnswer((_) async => testBass);
    });

    Widget buildWidget() {
      return MaterialApp(
        home: SpeakerSettingsPage(
          speaker: testSpeaker,
          apiService: mockApiService,
        ),
      );
    }

    testWidgets('shows loading indicator while fetching language',
        (WidgetTester tester) async {
      final completer = Completer<int>();
      when(mockApiService.getLanguage(any)).thenAnswer(
        (_) => completer.future,
      );

      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);

      completer.complete(3);
      await tester.pumpAndSettle();
    });

    testWidgets('displays current language after loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('displays German when language code is 2',
        (WidgetTester tester) async {
      when(mockApiService.getLanguage(any)).thenAnswer((_) async => 2);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('German'), findsOneWidget);
    });

    testWidgets('shows error message when loading fails',
        (WidgetTester tester) async {
      when(mockApiService.getLanguage(any))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error loading language'), findsOneWidget);
    });

    testWidgets('edit button is present after loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows language picker dialog when edit button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('calls setLanguage and updates UI after saving',
        (WidgetTester tester) async {
      when(mockApiService.setLanguage(any, any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<SpeakerLanguage>));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('German').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(mockApiService.setLanguage('192.168.1.100', 2)).called(1);
      expect(find.text('German'), findsOneWidget);
    });

    testWidgets('shows snackbar when setLanguage fails',
        (WidgetTester tester) async {
      when(mockApiService.setLanguage(any, any))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<SpeakerLanguage>));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text('German').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Failed to set language'), findsOneWidget);
    });

    testWidgets('cancel button closes dialog without saving',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(mockApiService.setLanguage(any, any));
      expect(find.text('Select Language'), findsNothing);
    });

    group('bass card', () {
      testWidgets('shows bass slider when supported',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Bass'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);
      });

      testWidgets('shows current bass value and min/max labels',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('-5'), findsOneWidget);
        expect(find.text('-9'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('shows Down, Up, and Reset buttons',
          (WidgetTester tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Down'), findsOneWidget);
        expect(find.text('Up'), findsOneWidget);
        expect(find.textContaining('Reset to default'), findsOneWidget);
      });

      testWidgets('Down button decrements bass by 1',
          (WidgetTester tester) async {
        // Load with actualBass = -5, then after Down it refetches as -6.
        when(mockApiService.setBass(any, any)).thenAnswer((_) async {});

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        when(mockApiService.getBass(any))
            .thenAnswer((_) async => const Bass(targetBass: -6, actualBass: -6));

        await tester.tap(find.text('Down'));
        await tester.pumpAndSettle();

        verify(mockApiService.setBass('192.168.1.100', -6)).called(1);
      });

      testWidgets('Up button increments bass by 1',
          (WidgetTester tester) async {
        when(mockApiService.setBass(any, any)).thenAnswer((_) async {});

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        when(mockApiService.getBass(any))
            .thenAnswer((_) async => const Bass(targetBass: -4, actualBass: -4));

        await tester.tap(find.text('Up'));
        await tester.pumpAndSettle();

        verify(mockApiService.setBass('192.168.1.100', -4)).called(1);
      });

      testWidgets('Reset button calls setBass with default value',
          (WidgetTester tester) async {
        when(mockApiService.setBass(any, any)).thenAnswer((_) async {});

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        when(mockApiService.getBass(any))
            .thenAnswer((_) async => const Bass(targetBass: 0, actualBass: 0));

        await tester.tap(find.textContaining('Reset to default'));
        await tester.pumpAndSettle();

        verify(mockApiService.setBass('192.168.1.100', 0)).called(1);
      });

      testWidgets('shows unsupported message when bass not available',
          (WidgetTester tester) async {
        when(mockApiService.getBassCapabilities(any))
            .thenAnswer((_) async => unsupportedBassCapabilities);

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Bass control not supported on this device'),
            findsOneWidget);
        expect(find.byType(Slider), findsNothing);
      });

      testWidgets('shows error and retry button when bass loading fails',
          (WidgetTester tester) async {
        when(mockApiService.getBassCapabilities(any))
            .thenThrow(Exception('Connection refused'));

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Error loading bass'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('retry reloads bass after error', (WidgetTester tester) async {
        when(mockApiService.getBassCapabilities(any))
            .thenThrow(Exception('Connection refused'));

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        when(mockApiService.getBassCapabilities(any))
            .thenAnswer((_) async => testBassCapabilities);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(find.byType(Slider), findsOneWidget);
      });

      testWidgets('calls setBass and getBass after slider change',
          (WidgetTester tester) async {
        when(mockApiService.setBass(any, any)).thenAnswer((_) async {});
        const updatedBass = Bass(targetBass: -3, actualBass: -3);
        when(mockApiService.getBass(any))
            .thenAnswer((_) async => updatedBass);

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        // Drag slider to trigger onChangeEnd
        await tester.drag(find.byType(Slider), const Offset(50, 0));
        await tester.pumpAndSettle();

        verify(mockApiService.setBass('192.168.1.100', any)).called(1);
        verify(mockApiService.getBass('192.168.1.100')).called(greaterThan(1));
      });

      testWidgets('shows snackbar when setBass fails',
          (WidgetTester tester) async {
        when(mockApiService.setBass(any, any))
            .thenThrow(Exception('Network error'));

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(Slider), const Offset(50, 0));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Failed to set bass'), findsOneWidget);
      });
    });
  });

  group('SpeakerLanguage', () {
    test('fromCode returns correct enum value', () {
      expect(SpeakerLanguage.fromCode(1), SpeakerLanguage.danish);
      expect(SpeakerLanguage.fromCode(3), SpeakerLanguage.english);
      expect(SpeakerLanguage.fromCode(25), SpeakerLanguage.hungarian);
    });

    test('fromCode returns null for unknown code', () {
      expect(SpeakerLanguage.fromCode(99), isNull);
    });

    test('all languages have correct codes', () {
      expect(SpeakerLanguage.english.code, 3);
      expect(SpeakerLanguage.german.code, 2);
      expect(SpeakerLanguage.czech.code, 15);
    });
  });
}
