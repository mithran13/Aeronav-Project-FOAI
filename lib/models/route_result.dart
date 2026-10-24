import 'airport_node.dart';

/// Data structure holding execution results and metrics for AI Search algorithms.
class RouteResult {
  final String algorithmName;
  final bool isSuccess;
  final List<AirportNode> path;
  final List<FlightEdge> legs;
  final double totalDistanceKm;
  final int nodesExplored;
  final double executionTimeMs;
  final int? depthLimit;
  final int maxDepthReached;
  final String statusMessage;

  RouteResult({
    required this.algorithmName,
    required this.isSuccess,
    required this.path,
    required this.legs,
    required this.totalDistanceKm,
    required this.nodesExplored,
    required this.executionTimeMs,
    this.depthLimit,
    this.maxDepthReached = 0,
    required this.statusMessage,
  });

  /// Readable summary hop string e.g. "MAA ➔ DXB ➔ JFK"
  String get hopSummary => path.map((node) => node.iata).join(' ➔ ');

  int get totalHops => path.length > 1 ? path.length - 1 : 0;
}
