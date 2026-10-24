import '../models/waypoint.dart';

class WaypointService {
  WaypointService._();
  static final WaypointService instance = WaypointService._();

  final List<Waypoint> _waypoints = const [
    Waypoint(
      ident: 'DVG',
      lat: 37.621312,
      lon: -122.378955,
      kind: WaypointKind.sid,
    ),
    Waypoint(
      ident: 'SFO',
      lat: 37.618805,
      lon: -122.375416,
      kind: WaypointKind.star,
    ),
    Waypoint(
      ident: 'MEL',
      lat: 38.145833,
      lon: -122.263889,
      kind: WaypointKind.sid,
    ),
  ];

  List<Waypoint> getAll() => List.unmodifiable(_waypoints);
}
