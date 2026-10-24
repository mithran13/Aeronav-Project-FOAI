import 'dart:math';
import '../models/airport_node.dart';
import '../models/route_result.dart';

/// Depth-Limited Search (DLS) Graph Search Algorithm.
/// Performs bounded depth-first search up to a maximum depth limit L.
class DepthLimitedSearch {
  static RouteResult findRoute({
    required Map<String, AirportNode> graph,
    required String startIata,
    required String goalIata,
    int depthLimit = 3,
  }) {
    final stopwatch = Stopwatch()..start();
    int nodesExplored = 0;
    int maxDepthReached = 0;

    final startNode = graph[startIata];
    final goalNode = graph[goalIata];

    if (startNode == null || goalNode == null) {
      stopwatch.stop();
      return RouteResult(
        algorithmName: 'Depth-Limited Search (DLS)',
        isSuccess: false,
        path: [],
        legs: [],
        totalDistanceKm: 0.0,
        nodesExplored: 0,
        executionTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
        depthLimit: depthLimit,
        maxDepthReached: 0,
        statusMessage: 'Invalid start or target airport specified.',
      );
    }

    final List<AirportNode> path = [startNode];
    final List<FlightEdge> legs = [];
    final Set<String> visitedInCurrentBranch = {startIata};

    bool recursiveDls(AirportNode current, int currentDepth) {
      nodesExplored++;
      maxDepthReached = max(maxDepthReached, currentDepth);

      if (current.iata == goalIata) {
        return true;
      }

      if (currentDepth >= depthLimit) {
        return false;
      }

      for (var edge in current.connections) {
        final neighbor = graph[edge.toIata];
        if (neighbor != null && !visitedInCurrentBranch.contains(edge.toIata)) {
          visitedInCurrentBranch.add(edge.toIata);
          path.add(neighbor);
          legs.add(edge);

          if (recursiveDls(neighbor, currentDepth + 1)) {
            return true;
          }

          // Backtrack
          path.removeLast();
          legs.removeLast();
          visitedInCurrentBranch.remove(edge.toIata);
        }
      }

      return false;
    }

    final bool found = recursiveDls(startNode, 0);
    stopwatch.stop();
    final double elapsedMs = stopwatch.elapsedMicroseconds / 1000.0;

    if (found) {
      double totalDist = legs.fold(0.0, (sum, edge) => sum + edge.distanceKm);
      return RouteResult(
        algorithmName: 'Depth-Limited Search (DLS)',
        isSuccess: true,
        path: List.unmodifiable(path),
        legs: List.unmodifiable(legs),
        totalDistanceKm: totalDist,
        nodesExplored: nodesExplored,
        executionTimeMs: elapsedMs,
        depthLimit: depthLimit,
        maxDepthReached: maxDepthReached,
        statusMessage: 'Route found within depth limit $depthLimit ($totalDist km, ${path.length - 1} hops).',
      );
    } else {
      return RouteResult(
        algorithmName: 'Depth-Limited Search (DLS)',
        isSuccess: false,
        path: [],
        legs: [],
        totalDistanceKm: 0.0,
        nodesExplored: nodesExplored,
        executionTimeMs: elapsedMs,
        depthLimit: depthLimit,
        maxDepthReached: maxDepthReached,
        statusMessage: 'No route found within maximum depth limit of $depthLimit.',
      );
    }
  }
}
