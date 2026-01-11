import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ueberboese_app/services/speaker_websocket_service.dart';
import 'package:ueberboese_app/models/volume.dart';
import 'package:ueberboese_app/models/now_playing.dart';

import 'speaker_websocket_service_test.mocks.dart';

@GenerateMocks([WebSocketChannel, WebSocketSink, Stream])
void main() {
  group('SpeakerWebsocketService', () {
    late MockWebSocketChannel mockChannel;
    late MockWebSocketSink mockSink;
    late StreamController<dynamic> messageController;

    setUp(() {
      mockChannel = MockWebSocketChannel();
      mockSink = MockWebSocketSink();
      messageController = StreamController<dynamic>.broadcast();

      when(mockChannel.stream).thenAnswer((_) => messageController.stream);
      when(mockChannel.sink).thenReturn(mockSink);
      when(mockSink.close(any, any)).thenAnswer((_) async => null);
    });

    tearDown(() {
      messageController.close();
    });

    test('creates service with correct IP address', () {
      final service = SpeakerWebsocketService('192.168.1.100');
      expect(service.ipAddress, equals('192.168.1.100'));
      service.dispose();
    });

    test('isConnected returns false initially', () {
      final service = SpeakerWebsocketService('192.168.1.100');
      expect(service.isConnected, isFalse);
      service.dispose();
    });

    test('parses volume update XML correctly', () async {
      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) => mockChannel,
      );

      final volumeUpdates = <Volume>[];
      service.volumeStream.listen((volume) {
        volumeUpdates.add(volume);
      });

      service.connect();

      const xmlMessage = '''<?xml version="1.0" encoding="UTF-8"?>
<updates deviceID="1004567890AA">
  <volumeUpdated>
    <volume deviceID="1004567890AA">
      <targetvolume>50</targetvolume>
      <actualvolume>50</actualvolume>
      <muteenabled>false</muteenabled>
    </volume>
  </volumeUpdated>
</updates>''';

      messageController.add(xmlMessage);
      await Future<void>.delayed(Duration.zero); // Let the stream process

      expect(volumeUpdates.length, 1);
      expect(volumeUpdates[0].targetVolume, 50);
      expect(volumeUpdates[0].actualVolume, 50);
      expect(volumeUpdates[0].muteEnabled, false);

      service.dispose();
    });

    test('parses now playing update XML correctly', () async {
      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) => mockChannel,
      );

      final nowPlayingUpdates = <NowPlaying>[];
      service.nowPlayingStream.listen((nowPlaying) {
        nowPlayingUpdates.add(nowPlaying);
      });

      service.connect();

      const xmlMessage = '''<?xml version="1.0" encoding="UTF-8"?>
<updates deviceID="1004567890AA">
  <nowPlayingUpdated>
    <nowPlaying>
      <ContentItem source="SPOTIFY" type="tracklisturl" location="/playback/container/abc123">
        <itemName>Test Track</itemName>
      </ContentItem>
      <track>Test Track</track>
      <artist>Test Artist</artist>
      <album>Test Album</album>
      <art>http://example.com/art.jpg</art>
      <playStatus>PLAY_STATE</playStatus>
      <shuffleSetting>SHUFFLE_OFF</shuffleSetting>
      <repeatSetting>REPEAT_OFF</repeatSetting>
    </nowPlaying>
  </nowPlayingUpdated>
</updates>''';

      messageController.add(xmlMessage);
      await Future<void>.delayed(Duration.zero);

      expect(nowPlayingUpdates.length, 1);
      expect(nowPlayingUpdates[0].track, 'Test Track');
      expect(nowPlayingUpdates[0].artist, 'Test Artist');
      expect(nowPlayingUpdates[0].album, 'Test Album');
      expect(nowPlayingUpdates[0].source, 'SPOTIFY');
      expect(nowPlayingUpdates[0].location, '/playback/container/abc123');

      service.dispose();
    });

    test('parses zone update correctly', () async {
      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) => mockChannel,
      );

      final zoneUpdates = <void>[];
      service.zoneStream.listen((_) {
        zoneUpdates.add(null);
      });

      service.connect();

      const xmlMessage = '''<?xml version="1.0" encoding="UTF-8"?>
<updates deviceID="1004567890AA">
  <zoneUpdated/>
</updates>''';

      messageController.add(xmlMessage);
      await Future<void>.delayed(Duration.zero);

      expect(zoneUpdates.length, 1);

      service.dispose();
    });

    test('handles malformed XML gracefully', () async {
      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) => mockChannel,
      );

      final volumeUpdates = <Volume>[];
      service.volumeStream.listen((volume) {
        volumeUpdates.add(volume);
      });

      service.connect();

      const malformedXml = 'This is not XML';
      messageController.add(malformedXml);
      await Future<void>.delayed(Duration.zero);

      // Should not crash, and no updates should be emitted
      expect(volumeUpdates.length, 0);

      service.dispose();
    });

    test('handles incomplete volume XML gracefully', () async {
      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) => mockChannel,
      );

      final volumeUpdates = <Volume>[];
      service.volumeStream.listen((volume) {
        volumeUpdates.add(volume);
      });

      service.connect();

      const incompleteXml = '''<?xml version="1.0" encoding="UTF-8"?>
<updates deviceID="1004567890AA">
  <volumeUpdated>
    <volume deviceID="1004567890AA">
      <targetvolume>50</targetvolume>
    </volume>
  </volumeUpdated>
</updates>''';

      messageController.add(incompleteXml);
      await Future<void>.delayed(Duration.zero);

      // Should not crash, and no updates should be emitted
      expect(volumeUpdates.length, 0);

      service.dispose();
    });

    test('dispose closes streams', () async {
      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) => mockChannel,
      );

      service.connect();

      // Use expectLater with emitsDone to properly wait for stream closure
      final volumeStreamDone = expectLater(service.volumeStream, emitsDone);
      final nowPlayingStreamDone = expectLater(service.nowPlayingStream, emitsDone);
      final zoneStreamDone = expectLater(service.zoneStream, emitsDone);

      service.dispose();

      await Future.wait([volumeStreamDone, nowPlayingStreamDone, zoneStreamDone]);
    });

    test('disconnect prevents reconnection', () {
      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) => mockChannel,
      );

      service.connect();
      expect(service.isConnected, isTrue);

      service.disconnect();
      expect(service.isConnected, isFalse);

      // Try to connect after disconnect
      service.connect();

      // Connection should not happen after disconnect
      expect(service.isConnected, isFalse);

      service.dispose();
    });

    test('uses gabbo protocol when connecting', () {
      List<String>? capturedProtocols;

      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) {
          capturedProtocols = protocols;
          return mockChannel;
        },
      );

      service.connect();

      expect(capturedProtocols, equals(['gabbo']));

      service.dispose();
    });

    test('handles stream errors gracefully', () async {
      final errorController = StreamController<dynamic>.broadcast();
      when(mockChannel.stream).thenAnswer((_) => errorController.stream);

      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) => mockChannel,
      );

      service.connect();
      expect(service.isConnected, isTrue);

      // Simulate a stream error
      errorController.addError(Exception('Connection error'));
      await Future<void>.delayed(Duration.zero);

      // Service should mark itself as disconnected
      expect(service.isConnected, isFalse);

      service.dispose();
      errorController.close();
    });

    test('handles stream done event', () async {
      final doneController = StreamController<dynamic>.broadcast();
      when(mockChannel.stream).thenAnswer((_) => doneController.stream);

      final service = SpeakerWebsocketService(
        '192.168.1.100',
        webSocketFactory: (uri, {protocols}) => mockChannel,
      );

      service.connect();
      expect(service.isConnected, isTrue);

      // Close the stream to simulate disconnection
      doneController.close();
      await Future<void>.delayed(Duration.zero);

      // Service should mark itself as disconnected
      expect(service.isConnected, isFalse);

      service.dispose();
    });
  });
}
