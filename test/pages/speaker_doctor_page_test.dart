import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ueberboese_app/main.dart';
import 'package:ueberboese_app/models/app_config.dart';
import 'package:ueberboese_app/models/speaker.dart';
import 'package:ueberboese_app/pages/speaker_doctor_page.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';
import 'package:ueberboese_app/widgets/envswitch_log_view.dart';

const _testSpeaker = Speaker(
  id: '1',
  name: 'Living Room',
  emoji: '🔊',
  ipAddress: '192.168.1.50',
  type: 'Bose Home Speaker',
  deviceId: 'ABC123',
);

const _configResponse = '''
margeServerUrl {
  text: "https://api.example.com"
}
bmxRegistryUrl {
  text: "https://api.example.com/bmx/registry/v1/services"
}
isZeroconfEnabled {
  text: true
}
''';

Widget _wrap(Widget child, {MyAppState? appState}) {
  return ChangeNotifierProvider.value(
    value: appState ?? MyAppState(),
    child: MaterialApp(home: child),
  );
}

/// Builds a service that simulates the speaker's telnet protocol.
///
/// `getSystemConfiguration` (first connect): sends config text and closes
/// the stream so the idle-timer resolves immediately.
///
/// `configureEnvswitch` (subsequent connects): sends the initial "->" prompt
/// and then responds "ok\n->" to each written command.
SpeakerSetupService _buildService({required String configResponseText}) {
  int callCount = 0;
  return SpeakerSetupService(
    envswitchDelay: Duration.zero,
    socketConnect: (host, port, {timeout}) async {
      callCount++;
      final controller = StreamController<Uint8List>();
      final isFirstCall = callCount == 1;

      if (!isFirstCall) {
        // Send initial ready-prompt for configureEnvswitch.
        controller.add(Uint8List.fromList('->'.codeUnits));
      }

      return _FakeSocket(
        stream: controller.stream,
        onWriteln: (_) {
          if (isFirstCall) {
            controller.add(Uint8List.fromList(configResponseText.codeUnits));
            controller.close();
          } else {
            controller.add(Uint8List.fromList('ok\n->'.codeUnits));
          }
        },
        onClose: () {
          if (!controller.isClosed) controller.close();
          return Future<void>.value();
        },
      );
    },
  );
}

SpeakerSetupService _failingService() {
  return SpeakerSetupService(
    envswitchDelay: Duration.zero,
    socketConnect: (host, port, {timeout}) =>
        Future.error(Exception('connection refused')),
  );
}

void main() {
  group('SpeakerDoctorPage', () {
    testWidgets('shows loading indicator initially', (tester) async {
      // Service whose socket factory never resolves.
      final service = SpeakerSetupService(
        envswitchDelay: Duration.zero,
        socketConnect: (host, port, {timeout}) =>
            Completer<Socket>().future,
      );

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service),
      ));

      // Don't pumpAndSettle — the loading spinner should appear before the
      // async completes.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows config table after successful load', (tester) async {
      final service = _buildService(configResponseText: _configResponse);

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service),
      ));
      await tester.pumpAndSettle();

      expect(find.text('margeServerUrl'), findsOneWidget);
      expect(find.text('https://api.example.com'), findsOneWidget);
      expect(find.text('isZeroconfEnabled'), findsOneWidget);
      expect(find.text('true'), findsOneWidget);
    });

    testWidgets('shows error message on socket failure', (tester) async {
      final service = _failingService();

      await tester.pumpWidget(_wrap(
        SpeakerDoctorPage(speaker: _testSpeaker, setupService: service),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed'), findsWidgets);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('connect button disabled when apiUrl is empty', (tester) async {
      final service = _buildService(configResponseText: _configResponse);
      final appState = MyAppState();
      // Set config directly to avoid SharedPreferences in tests.
      appState.config = const AppConfig(apiUrl: '');

      await tester.pumpWidget(
          _wrap(SpeakerDoctorPage(speaker: _testSpeaker, setupService: service),
              appState: appState));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Connect speaker to Überböse-API'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('connect button enabled when apiUrl is set', (tester) async {
      final service = _buildService(configResponseText: _configResponse);
      final appState = MyAppState();
      appState.config = const AppConfig(apiUrl: 'https://api.example.com');

      await tester.pumpWidget(
          _wrap(SpeakerDoctorPage(speaker: _testSpeaker, setupService: service),
              appState: appState));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Connect speaker to Überböse-API'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows EnvswitchLogView after successful connect',
        (tester) async {
      final service = _buildService(configResponseText: _configResponse);
      final appState = MyAppState();
      appState.config = const AppConfig(apiUrl: 'https://api.example.com');

      await tester.pumpWidget(
          _wrap(SpeakerDoctorPage(speaker: _testSpeaker, setupService: service),
              appState: appState));
      await tester.pumpAndSettle();

      await tester.tap(
          find.widgetWithText(FilledButton, 'Connect speaker to Überböse-API'));
      await tester.pumpAndSettle();

      expect(find.byType(EnvswitchLogView), findsOneWidget);
    });
  });
}

class _FakeSocket extends Stream<Uint8List> implements Socket {
  final Stream<Uint8List> stream;
  final void Function(String) onWriteln;
  final Future<void> Function() onClose;

  _FakeSocket({
    required this.stream,
    required this.onWriteln,
    required this.onClose,
  });

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      stream.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  void writeln([Object? object = '']) => onWriteln(object?.toString() ?? '');

  @override
  void write(Object? object) {}

  @override
  Future<void> flush() => Future<void>.value();

  @override
  Future<void> close() => onClose();

  @override
  void destroy() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
