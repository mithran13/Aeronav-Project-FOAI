import '../algorithms/haversine.dart';
import '../models/weather_hazard.dart';

class WeatherService {
  static final List<WeatherHazard> activeHazards = [
    // 1. South Asia / Bay of Bengal Monsoon Supercell
    const WeatherHazard(
      id: 'WX-BOB-01',
      name: 'Monsoon Convective Supercell "Meghna"',
      type: WeatherHazardType.thunderstorm,
      centerLat: 16.5,
      centerLon: 84.8,
      radiusKm: 280.0,
      severityDbz: 62.0,
      altitudeBaseFt: 2500,
      altitudeTopFt: 54000,
      movementHeadingDeg: 310.0,
      movementSpeedKts: 18.0,
      description: 'Severe lightning, hail cores, tops exceeding FL540. Heavy updrafts.',
    ),

    // 2. Arabian Sea Pre-Cyclone Depression
    const WeatherHazard(
      id: 'WX-ARB-02',
      name: 'Arabian Sea Convective Cluster',
      type: WeatherHazardType.thunderstorm,
      centerLat: 18.2,
      centerLon: 66.5,
      radiusKm: 240.0,
      severityDbz: 56.0,
      altitudeBaseFt: 3000,
      altitudeTopFt: 48000,
      movementHeadingDeg: 280.0,
      movementSpeedKts: 22.0,
      description: 'Squall line affecting Gulf-to-India air routes (DXB/BOM/MAA).',
    ),

    // 3. Middle East Dust & Mountain Wave Turbulence
    const WeatherHazard(
      id: 'WX-ME-03',
      name: 'Zagros Mountain Wave Clear Air Turbulence',
      type: WeatherHazardType.severeTurbulence,
      centerLat: 31.8,
      centerLon: 52.4,
      radiusKm: 220.0,
      severityDbz: 38.0,
      altitudeBaseFt: 28000,
      altitudeTopFt: 41000,
      movementHeadingDeg: 120.0,
      movementSpeedKts: 45.0,
      description: 'Severe vertical G-load shear. Recommended 2,000 ft altitude step down.',
    ),

    // 4. North Atlantic Polar Jet Stream Core (Tailwind Eastbound, Extreme Headwind Westbound)
    const WeatherHazard(
      id: 'WX-NAT-04',
      name: 'Sub-Polar Jet Stream Core (165 kt)',
      type: WeatherHazardType.jetStream,
      centerLat: 54.2,
      centerLon: -32.5,
      radiusKm: 380.0,
      severityDbz: 42.0,
      altitudeBaseFt: 31000,
      altitudeTopFt: 39000,
      movementHeadingDeg: 085.0,
      movementSpeedKts: 165.0,
      description: '165 kt Eastbound Jet Stream core. High fuel savings eastbound; avoid westbound.',
    ),

    // 5. Southeast Asia Squall Line
    const WeatherHazard(
      id: 'WX-SEA-05',
      name: 'Malacca Strait Tropical Squall',
      type: WeatherHazardType.thunderstorm,
      centerLat: 4.8,
      centerLon: 98.2,
      radiusKm: 210.0,
      severityDbz: 58.0,
      altitudeBaseFt: 1800,
      altitudeTopFt: 51000,
      movementHeadingDeg: 045.0,
      movementSpeedKts: 15.0,
      description: 'Fast-moving tropical squall line across Singapore-India airway.',
    ),

    // 6. Central European Frontal Convection
    const WeatherHazard(
      id: 'WX-EUR-06',
      name: 'Alpine Cold Front Thunderstorms',
      type: WeatherHazardType.thunderstorm,
      centerLat: 46.8,
      centerLon: 11.2,
      radiusKm: 190.0,
      severityDbz: 52.0,
      altitudeBaseFt: 4000,
      altitudeTopFt: 42000,
      movementHeadingDeg: 070.0,
      movementSpeedKts: 26.0,
      description: 'Embedded cumulonimbus with severe icing between FL160-FL240.',
    ),

    // 7. North American Great Plains Squall Line
    const WeatherHazard(
      id: 'WX-USA-07',
      name: 'Midwest Supercell Line',
      type: WeatherHazardType.thunderstorm,
      centerLat: 38.5,
      centerLon: -92.4,
      radiusKm: 260.0,
      severityDbz: 65.0,
      altitudeBaseFt: 2000,
      altitudeTopFt: 52000,
      movementHeadingDeg: 095.0,
      movementSpeedKts: 32.0,
      description: 'Derecho-producing supercells with severe turbulence and tornadic signatures.',
    ),
  ];

  /// Checks if a geographic line segment (flight leg) intersects or passes close to any weather hazard.
  static List<WeatherHazardIntersection> checkLegHazards(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final List<WeatherHazardIntersection> intersections = [];
    const int samplePoints = 30;

    for (var hazard in activeHazards) {
      double minDistance = double.infinity;
      double closestLat = lat1;
      double closestLon = lon1;

      for (int i = 0; i <= samplePoints; i++) {
        final t = i / samplePoints;
        final currentLat = lat1 + (lat2 - lat1) * t;
        final currentLon = lon1 + (lon2 - lon1) * t;

        final dist = HaversineCalculator.distanceKm(
          currentLat,
          currentLon,
          hazard.centerLat,
          hazard.centerLon,
        );

        if (dist < minDistance) {
          minDistance = dist;
          closestLat = currentLat;
          closestLon = currentLon;
        }
      }

      // If flight leg passes within hazard radius + safety margin (37 km / 20 NM)
      final safetyBufferKm = hazard.radiusKm + 37.0;
      if (minDistance < safetyBufferKm) {
        intersections.add(
          WeatherHazardIntersection(
            hazard: hazard,
            closestDistanceKm: minDistance,
            closestPointLat: closestLat,
            closestPointLon: closestLon,
            isDirectPenetration: minDistance < hazard.radiusKm,
          ),
        );
      }
    }

    return intersections;
  }
}

class WeatherHazardIntersection {
  final WeatherHazard hazard;
  final double closestDistanceKm;
  final double closestPointLat;
  final double closestPointLon;
  final bool isDirectPenetration;

  WeatherHazardIntersection({
    required this.hazard,
    required this.closestDistanceKm,
    required this.closestPointLat,
    required this.closestPointLon,
    required this.isDirectPenetration,
  });
}
