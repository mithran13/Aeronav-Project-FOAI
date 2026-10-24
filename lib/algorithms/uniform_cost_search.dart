import '../models/airport_node.dart';
import '../models/route_result.dart';

class _UcsNode {
  final AirportNode node;
  final double cost;
  final List<AirportNode> path;
  final List<FlightEdge> legs;

  _UcsNode({
    required this.node,
    required this.cost,
    required this.path,
    required this.legs,
  });
}

/// Uniform Cost Search (UCS) Algorithm (Dijkstra's Search).
/// Uninformed search expanding lowest cumulative path cost g(n).
class UniformCostSearch {
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
        algorithmName: 'Uniform Cost Search (UCS)',
        isSuccess: false,
        path: [],
        legs: [],
        totalDistanceKm: 0.0,
        nodesExplored: 0,
        executionTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
        statusMessage: 'Invalid start or target airport specified.',
      );
    }

    // Min-heap priority queue implemented via min-cost sorted insertion
    final List<_UcsNode> frontier = [
      _UcsNode(
        node: startNode,
        cost: 0.0,
        path: [startNode],
        legs: [],
      )
    ];

    final Map<String, double> bestCostToNode = {startIata: 0.0};

    while (frontier.isNotEmpty) {
      // Pick node with lowest path cost g(n)
      frontier.sort((a, b) => a.cost.compareTo(b.cost));
      final current = frontier.removeAt(0);
      nodesExplored++;

      if (current.node.iata == goalIata) {
        stopwatch.stop();
        return RouteResult(
          algorithmName: 'Uniform Cost Search (UCS)',
          isSuccess: true,
          path: List.unmodifiable(current.path),
          legs: List.unmodifiable(current.legs),
          totalDistanceKm: current.cost,
          nodesExplored: nodesExplored,
          executionTimeMs: stopwatch.elapsedMicroseconds / 1000.0,
          statusMessage: 'Optimal minimum cost route found (${current.cost.toStringAsFixed(1)} km, ${current.legs.length} hops).',
        );
      }

      for (var edge in current.node.connections) {
        final neighbor = graph[edge.toIata];
        if (neighbor == null) continue;

        final newCost = current.cost + edge.distanceKm;

        if (!bestCostToNode.containsKey(neighbor.iata) || newCost < bestCostToNode[neighbor.iata]!) {
          bestCostToNode[neighbor.iata] = newCost;

          frontier.add(
            _UcsNode(
              node: neighbor,
              cost: newCost,
              path: [...current.path, neighbor],
              legs: [...current.legs, edge],
            ),
          );
        }
      }
    }

    stopwatch.stop();
    return RouteResult(
      algorithmName: 'Uniform Cost Search (UCS)',
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
