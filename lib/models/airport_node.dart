/// Graph Node representing an airport in the AI navigation graph.
class AirportNode {
  final String iata;
  final String icao;
  final String name;
  final String city;
  final String country;
  final double latitude;
  final double longitude;
  final List<FlightEdge> connections;

  AirportNode({
    required this.iata,
    required this.icao,
    required this.name,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    List<FlightEdge>? connections,
  }) : connections = connections ?? [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AirportNode &&
          runtimeType == other.runtimeType &&
          iata == other.iata;

  @override
  int get hashCode => iata.hashCode;
}

/// Directed weighted edge representing a flight route connecting two airports.
class FlightEdge {
  final String fromIata;
  final String toIata;
  final double distanceKm;
  final String flightNumber;
  final String airline;

  FlightEdge({
    required this.fromIata,
    required this.toIata,
    required this.distanceKm,
    required this.flightNumber,
    required this.airline,
  });
}
