import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/services/speaker_discovery_service.dart';

void main() {
  group('SpeakerDiscoveryService.parseResponse', () {
    test('returns null for non-200 response', () {
      const response = 'HTTP/1.1 404 Not Found\r\n\r\n';
      expect(SpeakerDiscoveryService.parseResponse(response, '192.168.1.1'), isNull);
    });

    test('returns null when LOCATION header is missing', () {
      const response = 'HTTP/1.1 200 OK\r\nST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n';
      expect(SpeakerDiscoveryService.parseResponse(response, '192.168.1.1'), isNull);
    });

    test('returns null for empty response', () {
      expect(SpeakerDiscoveryService.parseResponse('', '192.168.1.1'), isNull);
    });

    test('parses valid 200 OK response with LOCATION header', () {
      const response =
          'HTTP/1.1 200 OK\r\n'
          'CACHE-CONTROL: max-age=1800\r\n'
          'LOCATION: http://192.168.1.42:8090/info\r\n'
          'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
          '\r\n';
      final result = SpeakerDiscoveryService.parseResponse(response, '192.168.1.42');
      expect(result, isNotNull);
      expect(result!.ip, '192.168.1.42');
      expect(result.location, 'http://192.168.1.42:8090/info');
    });

    test('is case-insensitive for LOCATION header', () {
      const response =
          'HTTP/1.1 200 OK\r\n'
          'Location: http://192.168.1.55:8090/info\r\n'
          '\r\n';
      final result = SpeakerDiscoveryService.parseResponse(response, '192.168.1.55');
      expect(result, isNotNull);
      expect(result!.location, 'http://192.168.1.55:8090/info');
    });

    test('trims whitespace from location value', () {
      const response =
          'HTTP/1.1 200 OK\r\n'
          'location:  http://192.168.1.10:8090/info  \r\n'
          '\r\n';
      final result = SpeakerDiscoveryService.parseResponse(response, '192.168.1.10');
      expect(result!.location, 'http://192.168.1.10:8090/info');
    });
  });
}
