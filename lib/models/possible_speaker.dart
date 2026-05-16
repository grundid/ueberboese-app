import 'package:ueberboese_app/models/speaker_info.dart';

class PossibleSpeaker {
  final String ip;
  final String location;
  SpeakerInfo? info;

  PossibleSpeaker({required this.ip, required this.location, this.info});
}
