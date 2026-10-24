import 'dart:math';

/// Utility class providing Haversine geographic distance calculation.
/// Used for flight edge weight g(n) and A* heuristic h(n).
class HaversineCalculator {
  static const double earthRadiusKm = 6371.0;

  /// Calculates the great-circle distance in kilometers between two latitude/longitude points.
  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final rLat1 = _toRadians(lat1);
    final rLat2 = _toRadians(lat2);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rLat1) * cos(rLat2) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
}
