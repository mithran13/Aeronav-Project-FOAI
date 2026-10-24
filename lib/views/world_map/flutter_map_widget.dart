import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/flight_item.dart';
import '../../models/route_result.dart';
import '../../models/weather_hazard.dart';
import '../../services/global_airport_service.dart';
import '../../services/weather_service.dart';
import '../../theme/app_colors.dart';

import '../../services/waypoint_service.dart';
import '../../models/waypoint.dart';

enum FlutterMapStyleMode { darkCockpit, streetView, satellite }

class FlutterWorldMapWidget extends StatefulWidget {
  final PassengerFlightItem activeFlight;
  final List<PassengerFlightItem> allFlights;
  final RouteResult? activeAiRoute;
  final Function(PassengerFlightItem) onSelectFlight;
  final Function(AirportInfo) onSelectAirport;
  final FlutterMapStyleMode styleMode;
  final MapController? mapController;
  final bool showWeatherRadar;

  const FlutterWorldMapWidget({
    super.key,
    required this.activeFlight,
    required this.allFlights,
    this.activeAiRoute,
    required this.onSelectFlight,
    required this.onSelectAirport,
    this.styleMode = FlutterMapStyleMode.darkCockpit,
    this.mapController,
    this.showWeatherRadar = true,
  });

  @override
  State<FlutterWorldMapWidget> createState() => _FlutterWorldMapWidgetState();
}

class _FlutterWorldMapWidgetState extends State<FlutterWorldMapWidget> {
  // Great-Circle Geodesic Arc Points Generator
  List<LatLng> _calculateGeodesicArcPoints(
    double startLat,
    double startLon,
    double endLat,
    double endLon, {
    int numPoints = 100,
  }) {
    final double p1 = startLat * pi / 180;
    final double l1 = startLon * pi / 180;
    final double p2 = endLat * pi / 180;
    final double l2 = endLon * pi / 180;

    final double d = 2 *
        asin(sqrt(pow(sin((p1 - p2) / 2), 2) +
            cos(p1) * cos(p2) * pow(sin((l1 - l2) / 2), 2)));

    if (d.abs() < 1e-5) {
      return [LatLng(startLat, startLon), LatLng(endLat, endLon)];
    }

    List<LatLng> pts = [];
    for (int i = 0; i <= numPoints; i++) {
      double f = i / numPoints;
      double A = sin((1 - f) * d) / sin(d);
      double B = sin(f * d) / sin(d);

      double x = A * cos(p1) * cos(l1) + B * cos(p2) * cos(l2);
      double y = A * cos(p1) * sin(l1) + B * cos(p2) * sin(l2);
      double z = A * sin(p1) + B * sin(p2);

      double lat = atan2(z, sqrt(x * x + y * y));
      double lon = atan2(y, x);

      pts.add(LatLng(lat * 180 / pi, lon * 180 / pi));
    }
    return pts;
  }

  String _getTileUrl(FlutterMapStyleMode mode) {
    switch (mode) {
      // Free OSM dark style via openstreetmap.org — no API key needed
      case FlutterMapStyleMode.darkCockpit:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
      // Standard OSM tiles — free, no API key
      case FlutterMapStyleMode.streetView:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
      // ESRI World Imagery — free, no API key
      case FlutterMapStyleMode.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
  }

  List<String> _getSubdomains(FlutterMapStyleMode mode) {
    switch (mode) {
      case FlutterMapStyleMode.darkCockpit:
        return ['a', 'b', 'c'];
      case FlutterMapStyleMode.streetView:
        return ['a', 'b', 'c'];
      case FlutterMapStyleMode.satellite:
        return [];
    }
  }

  // Build Waypoint markers (SID/STAR)
  List<Marker> _buildWaypointMarkers() {
    final waypoints = WaypointService.instance.getAll();
    return waypoints.map((wp) {
      final isSid = wp.kind == WaypointKind.sid;
      final color = isSid ? Colors.orangeAccent : Colors.lightBlueAccent;
      return Marker(
        point: LatLng(wp.lat, wp.lon),
        width: 70,
        height: 28,
        child: Tooltip(
          message: '${wp.ident} (${isSid ? "SID" : "STAR"})',
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              wp.ident,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override

  @override
  Widget build(BuildContext context) {
    // 1. Single Active Flight Route Arc
    final activeFlightArcPoints = _calculateGeodesicArcPoints(
      widget.activeFlight.origin.latitude,
      widget.activeFlight.origin.longitude,
      widget.activeFlight.destination.latitude,
      widget.activeFlight.destination.longitude,
    );

    // 2. AI Multi-Leg Route Arcs if active
    final List<List<LatLng>> aiRouteLegArcs = [];
    final Set<String> aiRouteIataSet = {};

    if (widget.activeAiRoute != null && widget.activeAiRoute!.isSuccess) {
      for (var node in widget.activeAiRoute!.path) {
        aiRouteIataSet.add(node.iata);
      }

      for (int i = 0; i < widget.activeAiRoute!.path.length - 1; i++) {
        final from = widget.activeAiRoute!.path[i];
        final to = widget.activeAiRoute!.path[i + 1];
        aiRouteLegArcs.add(_calculateGeodesicArcPoints(
          from.latitude,
          from.longitude,
          to.latitude,
          to.longitude,
        ));
      }
    }

    // 3. Airport Markers
    final airportMarkers = GlobalAirportService.globalAirports.map((airport) {
      bool isConnected = airport.iata == widget.activeFlight.origin.iata ||
          airport.iata == widget.activeFlight.destination.iata;
      bool isAiNode = aiRouteIataSet.contains(airport.iata);

      return Marker(
        point: LatLng(airport.latitude, airport.longitude),
        width: (isConnected || isAiNode) ? 36 : 24,
        height: (isConnected || isAiNode) ? 36 : 24,
        child: GestureDetector(
          onTap: () => widget.onSelectAirport(airport),
          child: Container(
            alignment: Alignment.center,
            child: Icon(
              Icons.location_on,
              color: isAiNode
                  ? Colors.cyanAccent
                  : (isConnected
                      ? AppColors.electricAmber
                      : AppColors.skyBlue.withValues(alpha: 0.7)),
              size: (isConnected || isAiNode) ? 28 : 18,
            ),
          ),
        ),
      );
    }).toList();

    // 4. Aircraft Markers with Heading Rotation
    final aircraftMarkers = widget.allFlights.map((flight) {
      bool isActive = flight.id == widget.activeFlight.id;

      return Marker(
        point: LatLng(flight.currentLat, flight.currentLon),
        width: isActive ? 48 : 36,
        height: isActive ? 48 : 36,
        child: GestureDetector(
          onTap: () => widget.onSelectFlight(flight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: flight.currentHeading * pi / 180,
                child: Icon(
                  Icons.flight,
                  color:
                      isActive ? AppColors.electricAmber : AppColors.electricBlue,
                  size: isActive ? 30 : 22,
                ),
              ),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.cockpitDark.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.electricAmber, width: 1),
                  ),
                  child: Text(
                    flight.flightNumber,
                    style: const TextStyle(
                      color: AppColors.electricAmber,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();

    // Build Polylines list
    final List<Polyline> polylines = [
      Polyline(
        points: activeFlightArcPoints,
        color: AppColors.electricBlue.withValues(alpha: 0.3),
        strokeWidth: 4.0,
      ),
      Polyline(
        points: activeFlightArcPoints,
        color: AppColors.electricAmber.withValues(alpha: 0.8),
        strokeWidth: 2.5,
      ),
    ];

    // Add AI Multi-Leg Polylines if available
    for (var legPoints in aiRouteLegArcs) {
      polylines.add(
        Polyline(
          points: legPoints,
          color: Colors.cyanAccent.withValues(alpha: 0.5),
          strokeWidth: 7.0,
        ),
      );
      polylines.add(
        Polyline(
          points: legPoints,
          color: Colors.cyanAccent,
          strokeWidth: 3.5,
        ),
      );
    }

    // 5. Convective Weather Hazards & Jet Stream Circles
    final weatherCircles = widget.showWeatherRadar
        ? WeatherService.activeHazards.map((hazard) {
            Color fillColor;
            Color strokeColor;
            if (hazard.severityDbz >= 60) {
              fillColor = Colors.purple.withValues(alpha: 0.25);
              strokeColor = Colors.purpleAccent;
            } else if (hazard.severityDbz >= 50) {
              fillColor = Colors.red.withValues(alpha: 0.22);
              strokeColor = Colors.redAccent;
            } else if (hazard.severityDbz >= 40) {
              fillColor = Colors.amber.withValues(alpha: 0.20);
              strokeColor = Colors.amberAccent;
            } else {
              fillColor = Colors.cyan.withValues(alpha: 0.18);
              strokeColor = Colors.cyanAccent;
            }

            return CircleMarker(
              point: LatLng(hazard.centerLat, hazard.centerLon),
              radius: hazard.radiusKm * 1000,
              useRadiusInMeter: true,
              color: fillColor,
              borderColor: strokeColor,
              borderStrokeWidth: 1.5,
            );
          }).toList()
        : <CircleMarker>[];

    final weatherMarkers = widget.showWeatherRadar
        ? WeatherService.activeHazards.map((hazard) {
            IconData iconData;
            Color iconColor;
            switch (hazard.type) {
              case WeatherHazardType.thunderstorm:
                iconData = Icons.bolt;
                iconColor = Colors.yellowAccent;
                break;
              case WeatherHazardType.severeTurbulence:
                iconData = Icons.waves;
                iconColor = Colors.orangeAccent;
                break;
              case WeatherHazardType.volcanicAsh:
                iconData = Icons.volcano;
                iconColor = Colors.redAccent;
                break;
              case WeatherHazardType.icing:
                iconData = Icons.ac_unit;
                iconColor = Colors.lightBlueAccent;
                break;
              case WeatherHazardType.jetStream:
                iconData = Icons.air;
                iconColor = Colors.cyanAccent;
                break;
            }

            return Marker(
              point: LatLng(hazard.centerLat, hazard.centerLon),
              width: 90,
              height: 48,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconData, color: iconColor, size: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: iconColor, width: 0.8),
                    ),
                    child: Text(
                      hazard.type == WeatherHazardType.jetStream
                          ? '${hazard.movementSpeedKts.toInt()} kt Jet'
                          : '${hazard.severityDbz.toInt()} dBZ',
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList()
        : <Marker>[];

    return FlutterMap(
      mapController: widget.mapController,
      options: const MapOptions(
        initialCenter: LatLng(20.0, 78.0),
        initialZoom: 3.0,
        minZoom: 1.5,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: _getTileUrl(widget.styleMode),
          subdomains: _getSubdomains(widget.styleMode),
          userAgentPackageName: 'com.aeronav.app',
        ),

        // Weather Convective Hazard Circles
        if (widget.showWeatherRadar)
          CircleLayer(
            circles: weatherCircles,
          ),

        // Outer Glow & Multi-Leg AI Flight Path Lines
        PolylineLayer(
          polylines: polylines,
        ),

        // Markers Layer (Weather + Airports + Aircraft)
        MarkerLayer(
          markers: [
            ...weatherMarkers,
            ...airportMarkers,
            ...aircraftMarkers,
            ..._buildWaypointMarkers(),
          ],
        ),
      ],
    );
  }
}
