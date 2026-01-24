class SpeakerInfo {
  final String name;
  final String type;
  final String deviceId;
  final String? margeUrl;
  final String? accountId;

  const SpeakerInfo({
    required this.name,
    required this.type,
    required this.deviceId,
    this.margeUrl,
    this.accountId,
  });
}
