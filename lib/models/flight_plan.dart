import 'dart:math';

class Waypoint {
  final String id;
  final String identifier; // e.g., JFK, MERIT, FLUKY, BOS
  final String name;
  final double latitude;
  final double longitude;
  final double altitudeFeet;
  final String type; // AIRPORT, VOR, NDB, FIX, WAYPOINT

  Waypoint({
    required this.id,
    required this.identifier,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.altitudeFeet = 0.0,
    this.type = 'FIX',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'identifier': identifier,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'altitudeFeet': altitudeFeet,
        'type': type,
      };

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
        id: json['id'] ?? '',
        identifier: json['identifier'] ?? '',
        name: json['name'] ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        altitudeFeet: (json['altitudeFeet'] as num?)?.toDouble() ?? 0.0,
        type: json['type'] ?? 'FIX',
      );
}

class AircraftSpecs {
  final String model;
  final String registration;
  final double cruiseSpeedKnots; // Kts
  final double fuelBurnGph; // Gallons or Lbs per hour
  final double maxCeilingFeet;

  const AircraftSpecs({
    required this.model,
    required this.registration,
    required this.cruiseSpeedKnots,
    required this.fuelBurnGph,
    required this.maxCeilingFeet,
  });

  static const List<AircraftSpecs> presets = [
    AircraftSpecs(
      model: 'Boeing 737-800',
      registration: 'N737AA',
      cruiseSpeedKnots: 450.0,
      fuelBurnGph: 850.0,
      maxCeilingFeet: 41000.0,
    ),
    AircraftSpecs(
      model: 'Airbus A320-200',
      registration: 'N320AF',
      cruiseSpeedKnots: 445.0,
      fuelBurnGph: 820.0,
      maxCeilingFeet: 39000.0,
    ),
    AircraftSpecs(
      model: 'Gulfstream G650',
      registration: 'N650GS',
      cruiseSpeedKnots: 516.0,
      fuelBurnGph: 490.0,
      maxCeilingFeet: 51000.0,
    ),
    AircraftSpecs(
      model: 'Cessna 172 Skyhawk',
      registration: 'N172SP',
      cruiseSpeedKnots: 122.0,
      fuelBurnGph: 9.5,
      maxCeilingFeet: 14000.0,
    ),
  ];
}

class FlightPlan {
  final String id;
  final String flightNumber;
  final Waypoint origin;
  final Waypoint destination;
  final Waypoint? alternate;
  final List<Waypoint> waypoints;
  final AircraftSpecs aircraft;
  final double cruiseAltitudeFeet;
  final DateTime scheduledDeparture;
  final String remarks;

  FlightPlan({
    required this.id,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    this.alternate,
    required this.waypoints,
    required this.aircraft,
    this.cruiseAltitudeFeet = 35000.0,
    required this.scheduledDeparture,
    this.remarks = 'VFR/IFR Flight Plan',
  });

  // Calculate total distance along waypoints in Nautical Miles
  double get totalDistanceNM {
    if (fullRouteWaypoints.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < fullRouteWaypoints.length - 1; i++) {
      total += calculateDistanceNM(
        fullRouteWaypoints[i].latitude,
        fullRouteWaypoints[i].longitude,
        fullRouteWaypoints[i + 1].latitude,
        fullRouteWaypoints[i + 1].longitude,
      );
    }
    return total;
  }

  // List of all points: Origin -> Waypoints -> Destination
  List<Waypoint> get fullRouteWaypoints {
    return [origin, ...waypoints, destination];
  }

  // Estimated Time Enroute in minutes
  double get estimatedFlightTimeHours {
    if (aircraft.cruiseSpeedKnots <= 0) return 0.0;
    return totalDistanceNM / aircraft.cruiseSpeedKnots;
  }

  // Estimated Fuel Required (lbs or gal)
  double get totalFuelRequired {
    return estimatedFlightTimeHours * aircraft.fuelBurnGph * 1.15; // 15% reserve
  }

  static double calculateDistanceNM(
      double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    // 12742 km is Earth diameter -> convert km to NM (1 km = 0.539957 NM)
    return 12742 * asin(sqrt(a)) * 0.539957;
  }

  static double calculateBearing(
      double lat1, double lon1, double lat2, double lon2) {
    final double p1 = lat1 * (pi / 180);
    final double p2 = lat2 * (pi / 180);
    final double dLon = (lon2 - lon1) * (pi / 180);

    final double y = sin(dLon) * cos(p2);
    final double x = cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dLon);

    final double brng = atan2(y, x);
    return (brng * (180 / pi) + 360) % 360;
  }
}
