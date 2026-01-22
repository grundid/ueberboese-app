import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/pages/presets/presets_page.dart';

void main() {
  group('PresetsPage', () {
    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PresetsPage(speakerIp: '192.168.1.100'),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays correct app bar title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PresetsPage(speakerIp: '192.168.1.100'),
        ),
      );

      // Should have "Manage Presets" title in app bar
      expect(find.text('Manage Presets'), findsOneWidget);
    });

    testWidgets('page builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PresetsPage(speakerIp: '192.168.1.100'),
        ),
      );

      // Widget should build successfully
      expect(find.byType(PresetsPage), findsOneWidget);
    });
  });
}
