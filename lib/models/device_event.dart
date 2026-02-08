/// Model class representing a device event from the Überböse API
class DeviceEvent {
  /// Event-specific data (varies by event type)
  final Map<String, dynamic> data;

  /// Monotonic time value
  final int monoTime;

  /// Event timestamp
  final DateTime time;

  /// Event type identifier
  final String type;

  DeviceEvent({
    required this.data,
    required this.monoTime,
    required this.time,
    required this.type,
  });

  /// Creates a DeviceEvent from JSON data
  factory DeviceEvent.fromJson(Map<String, dynamic> json) {
    return DeviceEvent(
      data: Map<String, dynamic>.from(json['data'] as Map),
      monoTime: json['monoTime'] as int,
      time: DateTime.parse(json['time'] as String),
      type: json['type'] as String,
    );
  }

  /// Converts this DeviceEvent to JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'monoTime': monoTime,
      'time': time.toIso8601String(),
      'type': type,
    };
  }
}
