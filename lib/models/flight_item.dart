import 'dart:math';

class AirportInfo {
  final String iata;
  final String icao;
  final String name;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final String rawTerminal;
  final String rawGate;
  final DateTime time;
  final String? baggageClaim;
  final String? weatherTemp;
  final String? weatherCondition;

  AirportInfo({
    required this.iata,
    required this.icao,
    required this.name,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required String terminal,
    required String gate,
    required this.time,
    this.baggageClaim,
    this.weatherTemp,
    this.weatherCondition,
  })  : rawTerminal = terminal,
        rawGate = gate;

  // Clean terminal string to prevent duplicate "Terminal Terminal 5" text
  String get terminal {
    String t = rawTerminal.replaceAll(RegExp(r'terminal\s*', caseSensitive: false), '').trim();
    return t.isEmpty ? '1' : t;
  }

  // Clean gate string
  String get gate {
    String g = rawGate.replaceAll(RegExp(r'gate\s*', caseSensitive: false), '').trim();
    return g.isEmpty ? 'A1' : g;
  }

  String get formattedTerminalGate => 'Terminal $terminal • Gate $gate';
}

enum FlightTimelineStep {
  checkIn,
  boarding,
  departed,
  cruising,
  descent,
  landing,
  arrived,
}

class FlightAlert {
  final String id;
  final String title;
  final String message;
  final String category; // "Gate", "Delay", "Weather", "Boarding"
  final DateTime timestamp;
  final bool isHighPriority;

  FlightAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isHighPriority = false,
  });
}

class PassengerFlightItem {
  final String id;
  final String flightNumber; // e.g. "AA 452"
  final String airlineName;  // e.g. "American Airlines"
  final String airlineCode;  // e.g. "AA"
  final AirportInfo origin;
  final AirportInfo destination;
  final String aircraftModel; // e.g. "Boeing 777-300ER"
  final String tailNumber;    // e.g. "N737AA"
  final String statusText;    // e.g. "In the Air • On Time"
  final bool isDelayed;
  final int delayMinutes;
  double progress;            // 0.0 to 1.0

  // Route Weather Specs
  final double windSpeedKts;
  final String windDirection;
  final String cloudCeiling;
  final String turbulenceRisk; // "None", "Light", "Moderate", "Severe"

  // Live Alerts list
  final List<FlightAlert> alerts;

  PassengerFlightItem({
    required this.id,
    required this.flightNumber,
    required this.airlineName,
    required this.airlineCode,
    required this.origin,
    required this.destination,
    required this.aircraftModel,
    required this.tailNumber,
    required this.statusText,
    this.isDelayed = false,
    this.delayMinutes = 0,
    this.progress = 0.45,
    this.windSpeedKts = 14.0,
    this.windDirection = 'WSW',
    this.cloudCeiling = 'Partly Cloudy @ 8,000 ft',
    this.turbulenceRisk = 'Light Turbulence',
    this.alerts = const [],
  });

  // Calculate current 7-step Flight Timeline Step
  FlightTimelineStep get currentTimelineStep {
    if (progress <= 0.0) return FlightTimelineStep.checkIn;
    if (progress < 0.08) return FlightTimelineStep.boarding;
    if (progress < 0.20) return FlightTimelineStep.departed;
    if (progress < 0.75) return FlightTimelineStep.cruising;
    if (progress < 0.90) return FlightTimelineStep.descent;
    if (progress < 1.0) return FlightTimelineStep.landing;
    return FlightTimelineStep.arrived;
  }

  // Calculate total distance in Miles (Great Circle)
  double get totalDistanceMiles {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        cos((destination.latitude - origin.latitude) * p) / 2 +
        cos(origin.latitude * p) *
            cos(destination.latitude * p) *
            (1 - cos((destination.longitude - origin.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 0.621371; // km to miles
  }

  double get distanceCoveredMiles => totalDistanceMiles * progress;
  double get distanceRemainingMiles => totalDistanceMiles * (1.0 - progress);

  // Total flight duration in hours
  double get totalFlightDurationHours => totalDistanceMiles / 510.0;

  // Time remaining formatted string
  String get timeRemainingFormatted {
    if (progress >= 1.0) return 'Landed';
    double hoursLeft = (totalFlightDurationHours * (1.0 - progress));
    int h = hoursLeft.floor();
    int m = ((hoursLeft - h) * 60).round();
    if (h == 0) return '${m}m remaining';
    return '${h}h ${m}m remaining';
  }

  // Calculate current interpolated airplane position (Latitude, Longitude)
  double get currentLat {
    return origin.latitude + (destination.latitude - origin.latitude) * progress;
  }

  double get currentLon {
    return origin.longitude + (destination.longitude - origin.longitude) * progress;
  }

  // Calculate plane heading bearing angle
  double get currentHeading {
    final double p1 = origin.latitude * (pi / 180);
    final double p2 = destination.latitude * (pi / 180);
    final double dLon = (destination.longitude - origin.longitude) * (pi / 180);

    final double y = sin(dLon) * cos(p2);
    final double x = cos(p1) * sin(p2) - sin(p1) * cos(p2) * cos(dLon);

    final double brng = atan2(y, x);
    return (brng * (180 / pi) + 360) % 360;
  }

  // Current altitude in feet
  double get currentAltitudeFeet {
    if (progress < 0.15) {
      return (progress / 0.15) * 35000.0;
    } else if (progress < 0.85) {
      return 35000.0;
    } else {
      return 35000.0 * (1.0 - (progress - 0.85) / 0.15);
    }
  }

  // Current speed in MPH
  double get currentSpeedMph {
    if (progress < 0.1 || progress > 0.9) return 280.0;
    return 535.0;
  }
}
