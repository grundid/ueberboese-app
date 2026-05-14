import 'package:flutter_test/flutter_test.dart';
import 'package:ueberboese_app/utils/url_utils.dart';

void main() {
  group('urlHostsMatch', () {
    test('returns true for identical URLs', () {
      expect(urlHostsMatch('http://srv.com', 'http://srv.com'), isTrue);
    });

    test('returns true when only path differs (url1 has path)', () {
      expect(urlHostsMatch('http://srv.com/api', 'http://srv.com'), isTrue);
    });

    test('returns true when only path differs (url2 has path)', () {
      expect(urlHostsMatch('http://srv.com', 'http://srv.com/v2'), isTrue);
    });

    test('returns true when both have different paths', () {
      expect(urlHostsMatch('http://srv.com/api', 'http://srv.com/v2'), isTrue);
    });

    test('returns true when paths and trailing slashes differ', () {
      expect(urlHostsMatch('http://srv.com/api/', 'http://srv.com'), isTrue);
    });

    test('returns false for different hosts', () {
      expect(urlHostsMatch('http://other.com', 'http://srv.com'), isFalse);
    });

    test('returns false for different schemes', () {
      expect(urlHostsMatch('http://srv.com', 'https://srv.com'), isFalse);
    });

    test('returns false for different ports', () {
      expect(urlHostsMatch('http://srv.com:8080', 'http://srv.com'), isFalse);
    });

    test('returns false when first URL is null', () {
      expect(urlHostsMatch(null, 'http://srv.com'), isFalse);
    });

    test('returns false when second URL is null', () {
      expect(urlHostsMatch('http://srv.com', null), isFalse);
    });

    test('returns false when first URL is empty', () {
      expect(urlHostsMatch('', 'http://srv.com'), isFalse);
    });

    test('returns false when second URL is empty', () {
      expect(urlHostsMatch('http://srv.com', ''), isFalse);
    });

    test('returns false for unparseable URLs', () {
      expect(urlHostsMatch('not a url', 'http://srv.com'), isFalse);
    });

    test('host comparison is case-insensitive', () {
      expect(urlHostsMatch('http://SRV.COM', 'http://srv.com'), isTrue);
    });

    test('scheme comparison is case-insensitive', () {
      expect(urlHostsMatch('HTTP://srv.com', 'http://srv.com'), isTrue);
    });

    test('returns true when explicit default port matches implicit', () {
      // Uri.tryParse normalizes port 80 for http to 0 (absent), so these match
      expect(urlHostsMatch('http://srv.com:80', 'http://srv.com'), isTrue);
    });
  });
}
