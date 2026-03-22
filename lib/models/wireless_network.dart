class WirelessNetwork {
  final String ssid;
  final int signalStrength;
  final bool secure;
  final String securityType;

  const WirelessNetwork({
    required this.ssid,
    required this.signalStrength,
    required this.secure,
    required this.securityType,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WirelessNetwork &&
        other.ssid == ssid &&
        other.signalStrength == signalStrength &&
        other.secure == secure &&
        other.securityType == securityType;
  }

  @override
  int get hashCode => Object.hash(ssid, signalStrength, secure, securityType);
}
