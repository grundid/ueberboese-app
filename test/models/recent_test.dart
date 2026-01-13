import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:ueberboese_app/models/recent.dart';

void main() {
  group('Recent', () {
    test('fromXml parses recent with all fields correctly', () {
      const xmlString = '''
      <recent deviceID="44EAD8A17CC7" utcTime="1768323670" id="1">
        <contentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s80044" sourceAccount="" isPresetable="true">
          <itemName>Radio TEDDY</itemName>
          <containerArt>http://cdn.example.com/logo.png</containerArt>
        </contentItem>
      </recent>
      ''';

      final document = XmlDocument.parse(xmlString);
      final recentElement = document.findAllElements('recent').first;

      final recent = Recent.fromXml(recentElement);

      expect(recent.deviceId, '44EAD8A17CC7');
      expect(recent.utcTime, 1768323670);
      expect(recent.id, '1');
      expect(recent.itemName, 'Radio TEDDY');
      expect(recent.containerArt, 'http://cdn.example.com/logo.png');
      expect(recent.source, 'TUNEIN');
      expect(recent.location, '/v1/playback/station/s80044');
      expect(recent.type, 'stationurl');
      expect(recent.isPresetable, true);
      expect(recent.sourceAccount, '');
    });

    test('fromXml parses recent without optional fields', () {
      const xmlString = '''
      <recent deviceID="1004567890AA" utcTime="1697087351" id="2">
        <contentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s33255" isPresetable="true">
          <itemName>89.7 | The River (College Radio)</itemName>
        </contentItem>
      </recent>
      ''';

      final document = XmlDocument.parse(xmlString);
      final recentElement = document.findAllElements('recent').first;

      final recent = Recent.fromXml(recentElement);

      expect(recent.deviceId, '1004567890AA');
      expect(recent.utcTime, 1697087351);
      expect(recent.id, '2');
      expect(recent.itemName, '89.7 | The River (College Radio)');
      expect(recent.containerArt, isNull);
      expect(recent.source, 'TUNEIN');
      expect(recent.location, '/v1/playback/station/s33255');
      expect(recent.type, 'stationurl');
      expect(recent.isPresetable, true);
    });

    test('fromXml parses Spotify recent with sourceAccount', () {
      const xmlString = '''
      <recent deviceID="44EAD8A17CC7" utcTime="1768304677" id="4">
        <contentItem source="SPOTIFY" type="tracklisturl" location="/playback/container/c3BvdGlmeTpwbGF5bGlzdDoybjZXMnA1QzBNQUQ5YTR6NXhUVDdu" sourceAccount="z5zt8py3wuxytbza4cxa431ge" isPresetable="true">
          <itemName>Komplett Entspannt</itemName>
        </contentItem>
      </recent>
      ''';

      final document = XmlDocument.parse(xmlString);
      final recentElement = document.findAllElements('recent').first;

      final recent = Recent.fromXml(recentElement);

      expect(recent.deviceId, '44EAD8A17CC7');
      expect(recent.utcTime, 1768304677);
      expect(recent.id, '4');
      expect(recent.itemName, 'Komplett Entspannt');
      expect(recent.containerArt, isNull);
      expect(recent.source, 'SPOTIFY');
      expect(
        recent.location,
        '/playback/container/c3BvdGlmeTpwbGF5bGlzdDoybjZXMnA1QzBNQUQ5YTR6NXhUVDdu',
      );
      expect(recent.type, 'tracklisturl');
      expect(recent.isPresetable, true);
      expect(recent.sourceAccount, 'z5zt8py3wuxytbza4cxa431ge');
    });

    test('fromXml parses LOCAL_INTERNET_RADIO recent', () {
      const xmlString = '''
      <recent deviceID="1004567890AA" utcTime="1699027517" id="2485930515">
        <contentItem source="LOCAL_INTERNET_RADIO" type="stationurl" location="https://content.api.bose.io/core02/svc-bmx-adapter-orion/prod/orion/station?data=eyJuYW1lIjoidGVzdCBzdGF0aW9uIiwiaW1hZ2VVcmwiOiIiLCJzdHJlYW1VcmwiOiJodHRwczovL2ZyZWV0ZXN0ZGF0YS5jb20vd3AtY29udGVudC91cGxvYWRzLzIwMjEvMDkvRnJlZV9UZXN0X0RhdGFfMU1CX01QMy5tcDMifQ%3D%3D" sourceAccount="" isPresetable="true">
          <itemName>test station</itemName>
        </contentItem>
      </recent>
      ''';

      final document = XmlDocument.parse(xmlString);
      final recentElement = document.findAllElements('recent').first;

      final recent = Recent.fromXml(recentElement);

      expect(recent.deviceId, '1004567890AA');
      expect(recent.utcTime, 1699027517);
      expect(recent.id, '2485930515');
      expect(recent.itemName, 'test station');
      expect(recent.containerArt, isNull);
      expect(recent.source, 'LOCAL_INTERNET_RADIO');
      expect(recent.type, 'stationurl');
      expect(recent.isPresetable, true);
    });

    test('fromXml parses recent with isPresetable false', () {
      const xmlString = '''
      <recent deviceID="1004567890AA" utcTime="1697084775" id="3">
        <contentItem source="TUNEIN" type="stationurl" location="/v1/playback/station/s297990" isPresetable="false">
          <itemName>MSNBC</itemName>
        </contentItem>
      </recent>
      ''';

      final document = XmlDocument.parse(xmlString);
      final recentElement = document.findAllElements('recent').first;

      final recent = Recent.fromXml(recentElement);

      expect(recent.deviceId, '1004567890AA');
      expect(recent.utcTime, 1697084775);
      expect(recent.id, '3');
      expect(recent.itemName, 'MSNBC');
      expect(recent.source, 'TUNEIN');
      expect(recent.location, '/v1/playback/station/s297990');
      expect(recent.type, 'stationurl');
      expect(recent.isPresetable, false);
    });

    test('toJson and fromJson work correctly', () {
      const recent = Recent(
        deviceId: '44EAD8A17CC7',
        utcTime: 1768323670,
        id: '1',
        itemName: 'Radio TEDDY',
        containerArt: 'http://cdn.example.com/logo.png',
        source: 'TUNEIN',
        location: '/v1/playback/station/s80044',
        type: 'stationurl',
        isPresetable: true,
        sourceAccount: '',
      );

      final json = recent.toJson();
      final fromJson = Recent.fromJson(json);

      expect(fromJson.deviceId, recent.deviceId);
      expect(fromJson.utcTime, recent.utcTime);
      expect(fromJson.id, recent.id);
      expect(fromJson.itemName, recent.itemName);
      expect(fromJson.containerArt, recent.containerArt);
      expect(fromJson.source, recent.source);
      expect(fromJson.location, recent.location);
      expect(fromJson.type, recent.type);
      expect(fromJson.isPresetable, recent.isPresetable);
      expect(fromJson.sourceAccount, recent.sourceAccount);
    });

    test('equality and hashCode work correctly', () {
      const recent1 = Recent(
        deviceId: '44EAD8A17CC7',
        utcTime: 1768323670,
        id: '1',
        itemName: 'Radio TEDDY',
        source: 'TUNEIN',
        location: '/v1/playback/station/s80044',
        type: 'stationurl',
        isPresetable: true,
      );

      const recent2 = Recent(
        deviceId: '44EAD8A17CC7',
        utcTime: 1768304677,
        id: '1',
        itemName: 'Different Name',
        source: 'SPOTIFY',
        location: '/different',
        type: 'tracklisturl',
        isPresetable: false,
      );

      const recent3 = Recent(
        deviceId: '1004567890AA',
        utcTime: 1768323670,
        id: '1',
        itemName: 'Radio TEDDY',
        source: 'TUNEIN',
        location: '/v1/playback/station/s80044',
        type: 'stationurl',
        isPresetable: true,
      );

      expect(recent1, equals(recent2)); // Same deviceId and id
      expect(recent1.hashCode, equals(recent2.hashCode));
      expect(recent1, isNot(equals(recent3))); // Different deviceId
    });
  });
}
