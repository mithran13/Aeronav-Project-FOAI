enum WeatherHazardType {
  thunderstorm,
  severeTurbulence,
  volcanicAsh,
  jetStream,
  icing,
}

class WeatherHazard {
  final String id;
  final String name;
  final WeatherHazardType type;
  final double centerLat;
  final double centerLon;
  final double radiusKm;
  final double severityDbz; // Radar reflectivity (35 - 68 dBZ)
  final int altitudeBaseFt;
  final int altitudeTopFt;
  final double movementHeadingDeg;
  final double movementSpeedKts;
  final String description;

  const WeatherHazard({
    required this.id,
    required this.name,
    required this.type,
    required this.centerLat,
    required this.centerLon,
    required this.radiusKm,
    required this.severityDbz,
    required this.altitudeBaseFt,
    required this.altitudeTopFt,
    required this.movementHeadingDeg,
    required this.movementSpeedKts,
    required this.description,
  });

  String get typeLabel {
    switch (type) {
      case WeatherHazardType.thunderstorm:
        return 'Convective Cell (CB)';
      case WeatherHazardType.severeTurbulence:
        return 'Clear Air Turbulence (CAT)';
      case WeatherHazardType.volcanicAsh:
        return 'Volcanic Ash Cloud';
      case WeatherHazardType.jetStream:
        return 'Jet Stream Core';
      case WeatherHazardType.icing:
        return 'Severe Airframe Icing';
    }
  }

  bool isSevere() => severityDbz >= 50.0 || type == WeatherHazardType.volcanicAsh;
}
