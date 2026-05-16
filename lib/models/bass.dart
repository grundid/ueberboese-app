class Bass {
  final int targetBass;
  final int actualBass;

  const Bass({required this.targetBass, required this.actualBass});
}

class BassCapabilities {
  final bool bassAvailable;
  final int bassMin;
  final int bassMax;
  final int bassDefault;

  const BassCapabilities({
    required this.bassAvailable,
    required this.bassMin,
    required this.bassMax,
    required this.bassDefault,
  });
}
