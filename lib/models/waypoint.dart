class Waypoint {
  final String ident; // e.g. "VOR1", "FIXA"
  final double lat;   // decimal degrees
  final double lon;   // decimal degrees
  final WaypointKind kind;

  const Waypoint({
    required this.ident,
    required this.lat,
    required this.lon,
    required this.kind,
  });
}

enum WaypointKind { sid, star }
