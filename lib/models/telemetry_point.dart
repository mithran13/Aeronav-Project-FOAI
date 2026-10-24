class TelemetryPoint {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double altitudeFeet;
  final double airspeedKnots;
  final double groundSpeedKnots;
  final double headingDegrees;
  final double pitchDegrees;
  final double rollDegrees;
  final double verticalSpeedFpm; // Feet per minute
  final double fuelRemainingLbs;

  TelemetryPoint({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitudeFeet,
    required this.airspeedKnots,
    required this.groundSpeedKnots,
    required this.headingDegrees,
    this.pitchDegrees = 0.0,
    this.rollDegrees = 0.0,
    this.verticalSpeedFpm = 0.0,
    required this.fuelRemainingLbs,
  });
}
