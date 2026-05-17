import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ueberboese_app/services/speaker_setup_service.dart';
import 'package:ueberboese_app/models/wireless_network.dart';

import 'speaker_setup_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('SpeakerSetupService', () {
    late MockClient mockClient;
    late SpeakerSetupService service;

    setUp(() {
      mockClient = MockClient();
      service = SpeakerSetupService(httpClient: mockClient);
    });

    group('performWirelessSiteSurvey', () {
      test('parses networks correctly', () async {
        const xmlResponse = '''<?xml version="1.0" encoding="UTF-8" ?>
<PerformWirelessSiteSurveyResponse error="none">
  <items>
    <item ssid="my_ssid" signalStrength="-58" secure="true">
      <securityTypes>
        <type>wpa_or_wpa2</type>
      </securityTypes>
    </item>
    <item ssid="open_network" signalStrength="-75" secure="false">
      <securityTypes>
        <type>none</type>
      </securityTypes>
    </item>
  </items>
</PerformWirelessSiteSurveyResponse>''';

        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(
            xmlResponse,
            200,
            headers: {'content-type': 'text/xml; charset=utf-8'},
          ),
        );

        final networks = await service.performWirelessSiteSurvey();

        expect(networks.length, 2);
        expect(networks[0].ssid, 'my_ssid');
        expect(networks[0].signalStrength, -58);
        expect(networks[0].secure, true);
        expect(networks[0].securityType, 'wpa_or_wpa2');
        expect(networks[1].ssid, 'open_network');
        expect(networks[1].secure, false);
        expect(networks[1].securityType, 'none');
      });

      test('requests the correct URL', () async {
        const xmlResponse =
            '<PerformWirelessSiteSurveyResponse error="none"><items></items></PerformWirelessSiteSurveyResponse>';
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response(xmlResponse, 200),
        );

        await service.performWirelessSiteSurvey();

        final captured = verify(mockClient.get(captureAny)).captured;
        expect(
          captured.first.toString(),
          'http://192.0.2.1:8090/performWirelessSiteSurvey',
        );
      });

      test('throws on non-200 status', () async {
        when(mockClient.get(any)).thenAnswer(
          (_) async => http.Response('error', 500),
        );

        await expectLater(
          service.performWirelessSiteSurvey(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('addWirelessProfile', () {
      test('sends correct POST request', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        await service.addWirelessProfile(
            'MySSID', 'mypassword', 'wpa_or_wpa2');

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(
          captured[0].toString(),
          'http://192.0.2.1:8090/addWirelessProfile',
        );
        expect(captured[2], contains('ssid="MySSID"'));
        expect(captured[2], contains('password="mypassword"'));
        expect(captured[2], contains('securityType="wpa_or_wpa2"'));
      });

      test('escapes XML special characters in ssid and password', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        await service.addWirelessProfile(
            'My&SSID', 'pass<word>', 'wpa_or_wpa2');

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(captured[2], contains('ssid="My&amp;SSID"'));
        expect(captured[2], contains('password="pass&lt;word&gt;"'));
      });

      test('throws on non-200 status', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('error', 400));

        await expectLater(
          service.addWirelessProfile('net', 'pw', 'wpa_or_wpa2'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('setMargeAccount', () {
      test('sends correct POST request', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        await service.setMargeAccount(
            '192.168.1.50', '12345678', 'test123');

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(
          captured[0].toString(),
          'http://192.168.1.50:8090/setMargeAccount',
        );
        expect(captured[2], contains('<accountId>12345678</accountId>'));
        expect(captured[2],
            contains('<userAuthToken>Bearer test123</userAuthToken>'));
      });

      test('throws on non-200 status', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('error', 401));

        await expectLater(
          service.setMargeAccount('192.168.1.50', 'acc', 'tok'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('leaveSetupMode', () {
      test('sends correct POST request', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('', 200));

        await service.leaveSetupMode();

        final captured = verify(mockClient.post(
          captureAny,
          headers: captureAnyNamed('headers'),
          body: captureAnyNamed('body'),
        )).captured;

        expect(
          captured[0].toString(),
          'http://192.0.2.1:8090/setup',
        );
        expect(captured[2], contains('SETUP_WIFI_LEAVE'));
      });

      test('throws on non-200 status', () async {
        when(mockClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('error', 500));

        await expectLater(
          service.leaveSetupMode(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('configureEnvswitch', () {
      test('connects to port 17000 and sends envswitch command', () async {
        final writtenLines = <String>[];
        // Simulate the speaker responding with 'ok' to each command.
        final responseController = StreamController<Uint8List>();

        final mockSocket = _MockSocket(
          stream: responseController.stream,
          onWriteln: (line) {
            writtenLines.add(line);
            // Echo a response back for each line written.
            responseController.add(Uint8List.fromList('ok\n'.codeUnits));
          },
          onFlush: () => Future<void>.value(),
          onClose: () {
            responseController.close();
            return Future<void>.value();
          },
        );

        String? connectedHost;
        int? connectedPort;

        final setupServiceWithSocket = SpeakerSetupService(
          httpClient: mockClient,
          envswitchDelay: Duration.zero,
          socketConnect: (host, port, {timeout}) async {
            connectedHost = host;
            connectedPort = port;
            return mockSocket;
          },
        );

        final log = await setupServiceWithSocket
            .configureEnvswitch('https://api.example.com');

        expect(connectedHost, '192.0.2.1');
        expect(connectedPort, 17000);
        expect(writtenLines, contains('envswitch boseurls set https://api.example.com https://api.example.com/updates/soundtouch'));
        expect(writtenLines, contains('sys configuration bmxRegistryUrl https://api.example.com/bmx/registry/v1/services'));
        expect(writtenLines, contains('sys configuration statsServerUrl https://api.example.com'));
        expect(writtenLines, contains('getpdo CurrentSystemConfiguration'));
        expect(writtenLines, contains('sys reboot'));
        expect(writtenLines, isNot(contains('exit')));
        // Log should contain sent lines prefixed with '>' and received with '<'
        expect(log.any((l) => l.startsWith('> envswitch')), isTrue);
        expect(log.any((l) => l.startsWith('> sys reboot')), isTrue);
        expect(log.any((l) => l.startsWith('< ok')), isTrue);
      });
    });
  });

  group('WirelessNetwork', () {
    test('equality', () {
      const n1 = WirelessNetwork(
          ssid: 'net', signalStrength: -60, secure: true, securityType: 'wpa_or_wpa2');
      const n2 = WirelessNetwork(
          ssid: 'net', signalStrength: -60, secure: true, securityType: 'wpa_or_wpa2');
      expect(n1, equals(n2));
    });

    test('inequality on different ssid', () {
      const n1 = WirelessNetwork(
          ssid: 'net1', signalStrength: -60, secure: true, securityType: 'wpa_or_wpa2');
      const n2 = WirelessNetwork(
          ssid: 'net2', signalStrength: -60, secure: true, securityType: 'wpa_or_wpa2');
      expect(n1, isNot(equals(n2)));
    });
  });
}

/// Minimal mock Socket for testing configureEnvswitch without dart:io.
class _MockSocket extends Stream<Uint8List> implements Socket {
  final Stream<Uint8List> stream;
  final void Function(String line) onWriteln;
  final Future<void> Function() onFlush;
  final Future<void> Function() onClose;

  _MockSocket({
    required this.stream,
    required this.onWriteln,
    required this.onFlush,
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
  void writeln([Object? object = '']) {
    onWriteln(object?.toString() ?? '');
  }

  @override
  void write(Object? object) {}

  @override
  Future<void> flush() => onFlush();

  @override
  Future<void> close() => onClose();

  @override
  void destroy() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
