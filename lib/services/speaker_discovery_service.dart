import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:udp/udp.dart';
import 'package:ueberboese_app/models/possible_speaker.dart';

class SpeakerDiscoveryService {
  static const _multicastAddress = '239.255.255.250';
  static const _multicastPort = 1900;
  static const _discoverMessage =
      'M-SEARCH * HTTP/1.1\r\n'
      'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'
      'MX: 3\r\n'
      'MAN: "ssdp:discover"\r\n'
      'HOST: 239.255.255.250:1900\r\n\r\n';

  Stream<PossibleSpeaker> discover({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    final seenIps = <String>{};
    final controller = StreamController<PossibleSpeaker>();

    final multicast = Endpoint.multicast(
      InternetAddress(_multicastAddress),
      port: const Port(_multicastPort),
    );

    final receiver = await UDP.bind(multicast);
    final data = utf8.encode(_discoverMessage);
    await receiver.send(data, multicast);

    receiver
        .asStream(timeout: timeout)
        .listen(
          (datagram) {
            if (datagram == null) return;
            final str = String.fromCharCodes(datagram.data);
            final parsed = parseResponse(str, datagram.address.address);
            if (parsed != null && seenIps.add(parsed.ip)) {
              controller.add(parsed);
            }
          },
          onError: (Object e) {
            receiver.close();
            controller.addError(e);
            controller.close();
          },
          onDone: () {
            receiver.close();
            controller.close();
          },
        );

    yield* controller.stream;
  }

  static PossibleSpeaker? parseResponse(String response, String senderIp) {
    final lines = response.split('\r\n');
    if (lines.isEmpty || !lines.first.startsWith('HTTP/1.1 200 OK')) {
      return null;
    }
    String? location;
    for (final line in lines) {
      if (line.toLowerCase().startsWith('location:')) {
        location = line.substring(9).trim();
        break;
      }
    }
    if (location == null) return null;
    return PossibleSpeaker(ip: senderIp, location: location);
  }
}
