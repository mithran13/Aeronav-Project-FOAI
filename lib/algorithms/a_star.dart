import '../models/airport_node.dart';
import '../models/route_result.dart';
import 'haversine.dart';

class _AStarNode {
  final AirportNode node;
  final double gCost; // Path cost from start to node n
  final double hCost; // Heuristic estimate from node n to goal
  double get fCost => gCost + hCost; // Evaluation function f(n) = g(n) + h(n)
  final List<AirportNode> path;
  final List<FlightEdge> legs;

  _AStarNode({
    required this.node,
    required this.gCost,
    required this.hCost,
    required this.path,
    required this.legs,
  });
}

/// A* Search Algorithm.
/// Informed search combining actual path cost g(n) and Haversine heuristic h(n): f(n) = g(n) + h(n).
class AStarSearch {
  static RouteResult findRoute({
    required Map<String, AirportNode> graph,
    required String startIata,
    required String goalIata,
  }) {
    final stopwatch = Stopwatch()..start();
    int nodesExplored = 0;

    final startNode = graph[startIata];
    final goalNode = graph[goalIata];

    if (startNode == null || goalNode == null) {
      stopwatch.stop();
      return RouteResult(
        algorithmName: 'A* Search',
        isSuccess: false,
        path: [],
        legs: [],
        totalDistanceKm: 0.0,
        nodesExplored: 0,
        executionTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
        statusMessage: 'Invalid start or target airport specified.',
      );
    }

    // Heuristic function h(n) = Haversine straight-line distance to goal
    double calculateH(AirportNode n) {
      return HaversineCalculator.distanceKm(
        n.latitude,
        n.longitude,
        goalNode.latitude,
        goalNode.longitude,
      );
    }

    final List<_AStarNode> openList = [
      _AStarNode(
        node: startNode,
        gCost: 0.0,
        hCost: calculateH(startNode),
        path: [startNode],
        legs: [],
      )
    ];

    final Map<String, double> bestGCostToNode = {startIata: 0.0};

    while (openList.isNotEmpty) {
      // Pick node with lowest evaluation function f(n) = g(n) + h(n)
      openList.sort((a, b) => a.fCost.compareTo(b.fCost));
      final current = openList.removeAt(0);
      nodesExplored++;

      if (current.node.iata == goalIata) {
        stopwatch.stop();
        return RouteResult(
          algorithmName: 'A* Search',
          isSuccess: true,
          path: List.unmodifiable(current.path),
          legs: List.unmodifiable(current.legs),
          totalDistanceKm: current.gCost,
          nodesExplored: nodesExplored,
          executionTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
          statusMessage: 'Optimal A* route found (${current.gCost.toStringAsFixed(1)} km, ${current.legs.length} hops).',
        );
      }

      for (var edge in current.node.connections) {
        final neighbor = graph[edge.toIata];
        if (neighbor == null) continue;

        final newGCost = current.gCost + edge.distanceKm;

        if (!bestGCostToNode.containsKey(neighbor.iata) || newGCost < bestGCostToNode[neighbor.iata]!) {
          bestGCostToNode[neighbor.iata] = newGCost;

          final hVal = calculateH(neighbor);
          openList.add(
            _AStarNode(
              node: neighbor,
              gCost: newGCost,
              hCost: hVal,
              path: [...current.path, neighbor],
              legs: [...current.legs, edge],
            ),
          );
        }
      }
    }

    stopwatch.stop();
    return RouteResult(
      algorithmName: 'A* Search',
      isSuccess: false,
      path: [],
      legs: [],
      totalDistanceKm: 0.0,
      nodesExplored: nodesExplored,
      executionTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
      statusMessage: 'No route connects start and target airports.',
    );
  }
}
