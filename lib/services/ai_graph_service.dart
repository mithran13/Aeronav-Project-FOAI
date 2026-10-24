import '../algorithms/haversine.dart';
import '../models/airport_node.dart';
import 'global_airport_service.dart';

class AiGraphService {
  static Map<String, AirportNode>? _cachedGraph;

  /// Returns the graph of airports and flight connections.
  static Map<String, AirportNode> getFlightGraph() {
    if (_cachedGraph != null) return _cachedGraph!;

    final Map<String, AirportNode> graph = {};

    // 1. Convert Global Airports to AirportNodes
    for (var info in GlobalAirportService.globalAirports) {
      graph[info.iata] = AirportNode(
        iata: info.iata,
        icao: info.icao,
        name: info.name,
        city: info.city,
        country: info.country,
        latitude: info.latitude,
        longitude: info.longitude,
      );
    }

    // 2. Define Flight Network Route Edges (Bi-directional connections)
    final List<Map<String, String>> rawConnections = [
      // India Domestic & Regional
      {'from': 'MAA', 'to': 'DEL', 'flight': 'AI 101', 'airline': 'Air India'},
      {'from': 'MAA', 'to': 'BOM', 'flight': '6E 204', 'airline': 'IndiGo'},
      {'from': 'MAA', 'to': 'BLR', 'flight': 'IX 812', 'airline': 'Air India Express'},
      {'from': 'MAA', 'to': 'COK', 'flight': '6E 412', 'airline': 'IndiGo'},
      {'from': 'MAA', 'to': 'SIN', 'flight': 'SQ 529', 'airline': 'Singapore Airlines'},
      {'from': 'MAA', 'to': 'DXB', 'flight': 'EK 543', 'airline': 'Emirates'},

      {'from': 'DEL', 'to': 'BOM', 'flight': 'AI 602', 'airline': 'Air India'},
      {'from': 'DEL', 'to': 'LHR', 'flight': 'AI 161', 'airline': 'Air India'},
      {'from': 'DEL', 'to': 'DXB', 'flight': 'EK 517', 'airline': 'Emirates'},
      {'from': 'DEL', 'to': 'HND', 'flight': 'JL 740', 'airline': 'Japan Airlines'},
      {'from': 'DEL', 'to': 'FRA', 'flight': 'LH 761', 'airline': 'Lufthansa'},

      {'from': 'BOM', 'to': 'DXB', 'flight': 'EK 501', 'airline': 'Emirates'},
      {'from': 'BOM', 'to': 'LHR', 'flight': 'BA 138', 'airline': 'British Airways'},
      {'from': 'BOM', 'to': 'SIN', 'flight': 'SQ 421', 'airline': 'Singapore Airlines'},

      {'from': 'BLR', 'to': 'DEL', 'flight': '6E 502', 'airline': 'IndiGo'},
      {'from': 'BLR', 'to': 'DXB', 'flight': 'EK 569', 'airline': 'Emirates'},
      {'from': 'BLR', 'to': 'SIN', 'flight': 'SQ 503', 'airline': 'Singapore Airlines'},

      {'from': 'HYD', 'to': 'MAA', 'flight': '6E 301', 'airline': 'IndiGo'},
      {'from': 'HYD', 'to': 'DEL', 'flight': 'AI 560', 'airline': 'Air India'},
      {'from': 'HYD', 'to': 'DXB', 'flight': 'EK 527', 'airline': 'Emirates'},

      {'from': 'CCU', 'to': 'DEL', 'flight': '6E 211', 'airline': 'IndiGo'},
      {'from': 'CCU', 'to': 'BKK', 'flight': 'TG 314', 'airline': 'Thai Airways'},
      {'from': 'CCU', 'to': 'SIN', 'flight': 'SQ 517', 'airline': 'Singapore Airlines'},

      // Middle East Hub
      {'from': 'DXB', 'to': 'LHR', 'flight': 'EK 001', 'airline': 'Emirates'},
      {'from': 'DXB', 'to': 'JFK', 'flight': 'EK 201', 'airline': 'Emirates'},
      {'from': 'DXB', 'to': 'CDG', 'flight': 'EK 073', 'airline': 'Emirates'},
      {'from': 'DXB', 'to': 'SYD', 'flight': 'EK 412', 'airline': 'Emirates'},

      // Asia Pacific Hubs
      {'from': 'SIN', 'to': 'HND', 'flight': 'SQ 632', 'airline': 'Singapore Airlines'},
      {'from': 'SIN', 'to': 'SYD', 'flight': 'SQ 211', 'airline': 'Singapore Airlines'},
      {'from': 'SIN', 'to': 'BKK', 'flight': 'SQ 706', 'airline': 'Singapore Airlines'},

      // Europe Transatlantic Hubs
      {'from': 'LHR', 'to': 'JFK', 'flight': 'BA 178', 'airline': 'British Airways'},
      {'from': 'LHR', 'to': 'CDG', 'flight': 'AF 1681', 'airline': 'Air France'},
      {'from': 'LHR', 'to': 'FRA', 'flight': 'BA 904', 'airline': 'British Airways'},

      {'from': 'CDG', 'to': 'JFK', 'flight': 'AF 006', 'airline': 'Air France'},
      {'from': 'CDG', 'to': 'FRA', 'flight': 'AF 1418', 'airline': 'Air France'},

      {'from': 'FRA', 'to': 'JFK', 'flight': 'LH 400', 'airline': 'Lufthansa'},

      // Pacific Transpacific Hubs
      {'from': 'HND', 'to': 'SFO', 'flight': 'JL 002', 'airline': 'Japan Airlines'},
      {'from': 'HND', 'to': 'LAX', 'flight': 'NH 106', 'airline': 'ANA'},

      // Americas Coast-to-Coast & Transpacific
      {'from': 'JFK', 'to': 'LAX', 'flight': 'AA 001', 'airline': 'American Airlines'},
      {'from': 'JFK', 'to': 'SFO', 'flight': 'UA 274', 'airline': 'United Airlines'},

      {'from': 'LAX', 'to': 'SYD', 'flight': 'QF 012', 'airline': 'Qantas'},
      {'from': 'LAX', 'to': 'SFO', 'flight': 'UA 512', 'airline': 'United Airlines'},
    ];

    for (var conn in rawConnections) {
      final fromIata = conn['from']!;
      final toIata = conn['to']!;
      final flight = conn['flight']!;
      final airline = conn['airline']!;

      final fromNode = graph[fromIata];
      final toNode = graph[toIata];

      if (fromNode != null && toNode != null) {
        final dist = HaversineCalculator.distanceKm(
          fromNode.latitude,
          fromNode.longitude,
          toNode.latitude,
          toNode.longitude,
        );

        // Forward Edge
        fromNode.connections.add(
          FlightEdge(
            fromIata: fromIata,
            toIata: toIata,
            distanceKm: dist,
            flightNumber: flight,
            airline: airline,
          ),
        );

        // Reverse Edge
        toNode.connections.add(
          FlightEdge(
            fromIata: toIata,
            toIata: fromIata,
            distanceKm: dist,
            flightNumber: flight,
            airline: airline,
          ),
        );
      }
    }

    _cachedGraph = graph;
    return graph;
  }
}
