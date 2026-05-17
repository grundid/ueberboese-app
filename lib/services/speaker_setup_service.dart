import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/wireless_network.dart';

/// IP address used by the speaker in access-point / setup mode.
const String kSetupSpeakerIp = '192.0.2.1';

typedef SocketConnect = Future<Socket> Function(String host, int port,
    {Duration? timeout});

class SpeakerSetupService {
  final http.Client? httpClient;
  final Duration timeout;
  final SocketConnect? socketConnect;
  final Duration envswitchDelay;

  SpeakerSetupService({
    this.httpClient,
    this.timeout = const Duration(seconds: 15),
    this.socketConnect,
    this.envswitchDelay = const Duration(seconds: 5),
  });

  http.Client _client() => httpClient ?? http.Client();

  bool _ownClient() => httpClient == null;

  Future<List<WirelessNetwork>> performWirelessSiteSurvey() async {
    final url = Uri.parse(
        'http://$kSetupSpeakerIp:8090/performWirelessSiteSurvey');
    final client = _client();
    try {
      final response = await client.get(url).timeout(timeout);
      if (response.statusCode != 200) {
        throw Exception(
            'Site survey failed: HTTP ${response.statusCode}');
      }
      final bodyText = utf8.decode(response.bodyBytes);
      final document = XmlDocument.parse(bodyText);
      final items = document.findAllElements('item');
      return items.map((item) {
        final ssid = item.getAttribute('ssid') ?? '';
        final signalStrength =
            int.tryParse(item.getAttribute('signalStrength') ?? '0') ?? 0;
        final secure = item.getAttribute('secure') == 'true';
        final typeElements = item.findAllElements('type');
        final securityType =
            typeElements.isNotEmpty ? typeElements.first.innerText : 'none';
        return WirelessNetwork(
          ssid: ssid,
          signalStrength: signalStrength,
          secure: secure,
          securityType: securityType,
        );
      }).toList();
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to perform site survey: $e');
    } finally {
      if (_ownClient()) client.close();
    }
  }

  Future<void> addWirelessProfile(
      String ssid, String password, String securityType) async {
    final url =
        Uri.parse('http://$kSetupSpeakerIp:8090/addWirelessProfile');
    final client = _client();
    final body =
        '<AddWirelessProfile>'
        '<profile ssid="${_escapeXml(ssid)}" '
        'password="${_escapeXml(password)}" securityType="$securityType" >'
        '</profile></AddWirelessProfile>';
    try {
      // Use a longer timeout: the speaker needs time to attempt connecting
      // to the Wi-Fi network before responding.
      final response = await client
          .post(url, headers: {'Content-Type': 'text/xml'}, body: body)
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        final responseBody = utf8.decode(response.bodyBytes).trim();
        final detail = responseBody.isNotEmpty ? '\n$responseBody' : '';
        throw Exception(
            'Add wireless profile failed: HTTP ${response.statusCode}$detail');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to add wireless profile: $e');
    } finally {
      if (_ownClient()) client.close();
    }
  }

  /// Connects to the speaker on port 17000, sends envswitch commands line by
  /// line, and returns a log of all sent ("> ") and received ("< ") lines.
  Future<List<String>> configureEnvswitch(String apiUrl) async {
    final connectFn = socketConnect ?? Socket.connect;
    final socket = await connectFn(
      kSetupSpeakerIp,
      17000,
      timeout: timeout,
    );
    final log = <String>[];
    try {
      final updatesUrl = '$apiUrl/updates/soundtouch';
      final commands = [
        'envswitch boseurls set $apiUrl $updatesUrl',
        'sys configuration bmxRegistryUrl $apiUrl/bmx/registry/v1/services',
        'sys configuration statsServerUrl $apiUrl',
        'getpdo CurrentSystemConfiguration',
        'sys reboot',
      ];

      // Wait for the speaker to be ready before sending commands.
      await Future<void>.delayed(envswitchDelay);

      // Buffer incoming data so we can capture responses per command.
      final buffer = StringBuffer();
      final dataCompleter = <Completer<String>>[];

      socket.cast<List<int>>().transform(utf8.decoder).listen((data) {
        buffer.write(data);
        if (dataCompleter.isNotEmpty && !dataCompleter.first.isCompleted) {
          dataCompleter.first.complete(buffer.toString());
          buffer.clear();
        }
      });

      for (final cmd in commands) {
        log.add('> $cmd');
        final completer = Completer<String>();
        dataCompleter.add(completer);
        socket.writeln(cmd);
        await socket.flush();
        // Wait up to 3 seconds for a response line.
        final response = await completer.future
            .timeout(const Duration(seconds: 3), onTimeout: () => '');
        if (response.trim().isNotEmpty) {
          for (final line in response.trim().split('\n')) {
            log.add('< ${line.trim()}');
          }
        }
        dataCompleter.remove(completer);
      }

      await socket.close();
      return log;
    } catch (e) {
      socket.destroy();
      if (e is Exception) rethrow;
      throw Exception('Failed to configure envswitch: $e');
    }
  }

  Future<void> setMargeAccount(
      String speakerIp, String accountId, String authToken) async {
    final url = Uri.parse('http://$speakerIp:8090/setMargeAccount');
    final client = _client();
    final body = '<PairDeviceWithAccount>'
        '<accountId>${_escapeXml(accountId)}</accountId>'
        '<userAuthToken>Bearer ${_escapeXml(authToken)}</userAuthToken>'
        '</PairDeviceWithAccount>';
    try {
      final response = await client
          .post(
            url,
            headers: {
              'Content-Type': 'application/xml',
              'Accept': 'application/xml',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        throw Exception(
            'Set Marge account failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to set Marge account: $e');
    } finally {
      if (_ownClient()) client.close();
    }
  }

  Future<void> leaveSetupMode() async {
    final url = Uri.parse('http://$kSetupSpeakerIp:8090/setup');
    final client = _client();
    const body = '<setupState state="SETUP_WIFI_LEAVE" />';
    try {
      final response = await client
          .post(url, headers: {'Content-Type': 'text/xml'}, body: body)
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw Exception(
            'Leave setup mode failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to leave setup mode: $e');
    } finally {
      if (_ownClient()) client.close();
    }
  }

  String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
