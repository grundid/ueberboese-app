import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
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

  group('SpeakerSettingsPage', () {
    late MockSpeakerApiService mockApiService;

    setUp(() {
      mockApiService = MockSpeakerApiService();
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

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(3);
      await tester.pumpAndSettle();
    });

    testWidgets('displays current language after loading',
        (WidgetTester tester) async {
      when(mockApiService.getLanguage(any)).thenAnswer((_) async => 3);

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
      when(mockApiService.getLanguage(any)).thenAnswer((_) async => 3);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows language picker dialog when edit button is tapped',
        (WidgetTester tester) async {
      when(mockApiService.getLanguage(any)).thenAnswer((_) async => 3);

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
      when(mockApiService.getLanguage(any)).thenAnswer((_) async => 3);
      when(mockApiService.setLanguage(any, any)).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Open the dropdown inside the dialog
      await tester.tap(find.byType(DropdownButtonFormField<SpeakerLanguage>));
      await tester.pumpAndSettle();

      // Tap German in the dropdown menu
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
      when(mockApiService.getLanguage(any)).thenAnswer((_) async => 3);
      when(mockApiService.setLanguage(any, any))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Open the dropdown inside the dialog
      await tester.tap(find.byType(DropdownButtonFormField<SpeakerLanguage>));
      await tester.pumpAndSettle();

      // Tap German in the dropdown menu
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
      when(mockApiService.getLanguage(any)).thenAnswer((_) async => 3);

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(mockApiService.setLanguage(any, any));
      expect(find.text('Select Language'), findsNothing);
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
