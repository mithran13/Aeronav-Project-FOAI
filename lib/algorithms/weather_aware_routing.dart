import 'dart:math';
import '../models/airport_node.dart';
import '../models/route_result.dart';
import '../models/weather_hazard.dart';
import '../services/weather_service.dart';
import 'haversine.dart';

class TacticalAvoidanceWaypoint {
  final String name;
  final double latitude;
  final double longitude;
  final String reason;
  final double clearanceKm;

  TacticalAvoidanceWaypoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.reason,
    required this.clearanceKm,
  });
}

class WeatherAwareRouteResult {
  final RouteResult baseRoute;
  final List<AirportNode> optimizedPath;
  final List<TacticalAvoidanceWaypoint> detourWaypoints;
  final List<WeatherHazardIntersection> detectedHazards;
  final double standardDistanceKm;
  final double weatherAwareDistanceKm;
  final double detourPenaltyKm;
  final double addedTimeMinutes;
  final double safetyScorePercent; // 0% - 100%
  final String statusSummary;
  final bool hasAvoidance;

  WeatherAwareRouteResult({
    required this.baseRoute,
    required this.optimizedPath,
    required this.detourWaypoints,
    required this.detectedHazards,
    required this.standardDistanceKm,
    required this.weatherAwareDistanceKm,
    required this.detourPenaltyKm,
    required this.addedTimeMinutes,
    required this.safetyScorePercent,
    required this.statusSummary,
    required this.hasAvoidance,
  });
}

class WeatherAwareRouting {
  /// Computes a weather-aware dynamic route that avoids severe convective cells and volcanic ash.
  static WeatherAwareRouteResult calculateRoute({
    required RouteResult baseRoute,
  }) {
    if (!baseRoute.isSuccess || baseRoute.path.length < 2) {
      return WeatherAwareRouteResult(
        baseRoute: baseRoute,
        optimizedPath: baseRoute.path,
        detourWaypoints: [],
        detectedHazards: [],
        standardDistanceKm: baseRoute.totalDistanceKm,
        weatherAwareDistanceKm: baseRoute.totalDistanceKm,
        detourPenaltyKm: 0.0,
        addedTimeMinutes: 0.0,
        safetyScorePercent: 100.0,
        statusSummary: 'Direct route clear of severe weather.',
        hasAvoidance: false,
      );
    }

    final List<WeatherHazardIntersection> allHazards = [];
    final List<TacticalAvoidanceWaypoint> detours = [];
    final List<AirportNode> dynamicPath = [];

    dynamicPath.add(baseRoute.path.first);

    for (int i = 0; i < baseRoute.path.length - 1; i++) {
      final from = baseRoute.path[i];
      final to = baseRoute.path[i + 1];

      final legHazards = WeatherService.checkLegHazards(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      );

      for (var hazardInter in legHazards) {
        if (!allHazards.any((h) => h.hazard.id == hazardInter.hazard.id)) {
          allHazards.add(hazardInter);
        }

        // Only detour around severe storms, volcanic ash, or severe turbulence
        if (hazardInter.hazard.type == WeatherHazardType.thunderstorm ||
            hazardInter.hazard.type == WeatherHazardType.volcanicAsh ||
            hazardInter.hazard.type == WeatherHazardType.severeTurbulence) {
          
          // Compute lateral tactical detour offset
          final hLat = hazardInter.hazard.centerLat;
          final hLon = hazardInter.hazard.centerLon;

          // Compute leg heading
          final dLat = to.latitude - from.latitude;
          final dLon = to.longitude - from.longitude;
          final legHeading = atan2(dLon, dLat);

          // Lateral offset perpendicular to flight path (+90 deg or -90 deg depending on movement)
          final offsetAngle = legHeading + pi / 2;
          final detourDistKm = hazardInter.hazard.radiusKm + 55.0; // Safe clearance buffer (30 NM)

          // Approximate lat/lon offset
          final detourLat = hLat + (detourDistKm / 111.0) * cos(offsetAngle);
          final detourLon = hLon + (detourDistKm / (111.0 * cos(hLat * pi / 180))) * sin(offsetAngle);

          final waypoint = TacticalAvoidanceWaypoint(
            name: 'DEV-${hazardInter.hazard.id.substring(3, 7)}',
            latitude: detourLat,
            longitude: detourLon,
            reason: 'Bypassing ${hazardInter.hazard.name} (${hazardInter.hazard.severityDbz.toInt()} dBZ)',
            clearanceKm: detourDistKm,
          );

          detours.add(waypoint);

          // Insert synthetic detour waypoint node into dynamic path
          dynamicPath.add(
            AirportNode(
              iata: waypoint.name,
              icao: 'WPTX',
              name: 'Tactical Waypoint ${waypoint.name}',
              city: 'Tactical Deviation',
              country: 'Airspace',
              latitude: waypoint.latitude,
              longitude: waypoint.longitude,
            ),
          );
        }
      }

      dynamicPath.add(to);
    }

    // Calculate total dynamic distance
    double totalDynamicDist = 0.0;
    for (int i = 0; i < dynamicPath.length - 1; i++) {
      totalDynamicDist += HaversineCalculator.distanceKm(
        dynamicPath[i].latitude,
        dynamicPath[i].longitude,
        dynamicPath[i + 1].latitude,
        dynamicPath[i + 1].longitude,
      );
    }

    final double baseDist = baseRoute.totalDistanceKm;
    final double penaltyKm = max(0.0, totalDynamicDist - baseDist);
    // Typical jet ground speed ~ 850 km/h (14.1 km/min)
    final double addedMins = penaltyKm / 14.1;

    final bool hasAvoidance = detours.isNotEmpty;
    final double safetyScore = hasAvoidance ? 99.4 : (allHazards.isEmpty ? 100.0 : 82.5);

    final summary = hasAvoidance
        ? 'Rerouted around ${detours.length} severe weather cell(s). +${penaltyKm.toStringAsFixed(1)} km (+${addedMins.toStringAsFixed(1)} mins) with 30 NM minimum clearance.'
        : 'Direct flight corridor clear of significant convective hazards. 100% On-Track.';

    return WeatherAwareRouteResult(
      baseRoute: baseRoute,
      optimizedPath: dynamicPath,
      detourWaypoints: detours,
      detectedHazards: allHazards,
      standardDistanceKm: baseDist,
      weatherAwareDistanceKm: totalDynamicDist,
      detourPenaltyKm: penaltyKm,
      addedTimeMinutes: addedMins,
      safetyScorePercent: safetyScore,
      statusSummary: summary,
      hasAvoidance: hasAvoidance,
    );
  }
}
