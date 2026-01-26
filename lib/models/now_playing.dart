class NowPlaying {
  final String? track;
  final String? artist;
  final String? album;
  final String? art;
  final String? artImageStatus;
  final String? shuffleSetting;
  final String? repeatSetting;
  final String? playStatus;
  final String? location;
  final String? source;
  final String? sourceAccount;

  const NowPlaying({
    this.track,
    this.artist,
    this.album,
    this.art,
    this.artImageStatus,
    this.shuffleSetting,
    this.repeatSetting,
    this.playStatus,
    this.location,
    this.source,
    this.sourceAccount,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NowPlaying &&
        other.track == track &&
        other.artist == artist &&
        other.album == album &&
        other.art == art &&
        other.artImageStatus == artImageStatus &&
        other.shuffleSetting == shuffleSetting &&
        other.repeatSetting == repeatSetting &&
        other.playStatus == playStatus &&
        other.location == location &&
        other.source == source &&
        other.sourceAccount == sourceAccount;
  }

  @override
  int get hashCode {
    return Object.hash(
      track,
      artist,
      album,
      art,
      artImageStatus,
      shuffleSetting,
      repeatSetting,
      playStatus,
      location,
      source,
      sourceAccount,
    );
  }
}
