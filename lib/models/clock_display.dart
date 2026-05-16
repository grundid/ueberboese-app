class ClockConfig {
  static const format12h = 'TIME_FORMAT_12HOUR_ID';
  static const format24h = 'TIME_FORMAT_24HOUR_ID';

  final bool userEnable;
  final String timeFormat;
  final int brightnessLevel;
  final String timezoneInfo;
  final int userOffsetMinute;
  final int userUtcTime;

  const ClockConfig({
    required this.userEnable,
    required this.timeFormat,
    required this.brightnessLevel,
    required this.timezoneInfo,
    required this.userOffsetMinute,
    required this.userUtcTime,
  });

  bool get is24Hour => timeFormat == format24h;

  ClockConfig copyWith({
    bool? userEnable,
    String? timeFormat,
    int? brightnessLevel,
  }) {
    return ClockConfig(
      userEnable: userEnable ?? this.userEnable,
      timeFormat: timeFormat ?? this.timeFormat,
      brightnessLevel: brightnessLevel ?? this.brightnessLevel,
      timezoneInfo: timezoneInfo,
      userOffsetMinute: userOffsetMinute,
      userUtcTime: userUtcTime,
    );
  }
}
