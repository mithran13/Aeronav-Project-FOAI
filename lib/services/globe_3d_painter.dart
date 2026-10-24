import 'dart:math';
import 'package:flutter/material.dart';
import '../models/flight_item.dart';
import '../theme/app_colors.dart';

class Globe3dPainter extends CustomPainter {
  final PassengerFlightItem activeFlight;
  final List<PassengerFlightItem> allFlights;
  final double rotX; // 3D Tilt pitch angle
  final double rotY; // 3D Yaw rotation angle
  final double zoomLevel;
  final bool isDarkTheme;

  Globe3dPainter({
    required this.activeFlight,
    required this.allFlights,
    required this.rotX,
    required this.rotY,
    required this.zoomLevel,
    this.isDarkTheme = true,
  });

  // 3D Spherical Coordinate Projection (Lat/Lon/Alt -> 3D Screen Point)
  Offset? project3D(double lat, double lon, double radius, Size size, {double altOffset = 0.0}) {
    final center = Offset(size.width / 2, size.height / 2);
    double r = radius * zoomLevel + altOffset;

    double phi = (90 - lat) * (pi / 180);
    double theta = (lon + rotY) * (pi / 180);

    // 3D Cartesian coordinates
    double x = r * sin(phi) * cos(theta);
    double y = r * cos(phi);
    double z = r * sin(phi) * sin(theta);

    // Rotate 3D point around X-axis by tilt angle rotX
    double radX = rotX * (pi / 180);
    double yRot = y * cos(radX) - z * sin(radX);
    double zRot = y * sin(radX) + z * cos(radX);

    // Back-face culling: If zRot < 0, point is behind the 3D Earth sphere
    if (zRot < -r * 0.2) return null;

    return center + Offset(x, -yRot);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    double baseRadius = min(size.width, size.height) * 0.36;

    // 1. Draw 3D Outer Atmosphere Glow & Earth Sphere Base
    final oceanPaint = Paint()
      ..color = isDarkTheme ? const Color(0xFF0D1C38) : const Color(0xFF0284C7)
      ..style = PaintingStyle.fill;

    final atmospherePaint = Paint()
      ..color = AppColors.skyBlue.withValues(alpha: isDarkTheme ? 0.3 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * zoomLevel;

    canvas.drawCircle(center, baseRadius * zoomLevel, oceanPaint);
    canvas.drawCircle(center, baseRadius * zoomLevel + 2, atmospherePaint);

    // 2. Draw 3D Latitude & Longitude Graticule Mesh Lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDarkTheme ? 0.12 : 0.25)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double lat = -60; lat <= 60; lat += 30) {
      final path = Path();
      bool moved = false;
      for (double lon = -180; lon <= 180; lon += 10) {
        Offset? pt = project3D(lat, lon, baseRadius, size);
        if (pt != null) {
          if (!moved) {
            path.moveTo(pt.dx, pt.dy);
            moved = true;
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        } else {
          moved = false;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // 3. Draw 3D Continents Projected onto the Sphere
    final landPaint = Paint()
      ..color = isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;

    final landBorderPaint = Paint()
      ..color = isDarkTheme ? AppColors.electricBlue : const Color(0xFF94A3B8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    _draw3DContinents(canvas, size, baseRadius, landPaint, landBorderPaint);

    // 4. Draw 3D Curved Flight Trajectory Arcs
    for (var flight in allFlights) {
      bool isActive = flight.id == activeFlight.id;
      _draw3DFlightArc(canvas, size, baseRadius, flight, isActive);
    }

    // 5. Draw 3D Airport Pins
    _draw3DAirportPin(canvas, size, baseRadius, activeFlight.origin, isOrigin: true);
    _draw3DAirportPin(canvas, size, baseRadius, activeFlight.destination, isOrigin: false);

    // 6. Draw 3D Animated Airplane Elevated above Earth Surface
    _draw3DActivePlane(canvas, size, baseRadius, activeFlight);
  }

  void _draw3DContinents(Canvas canvas, Size size, double radius, Paint fill, Paint stroke) {
    List<List<Point<double>>> continents = [
      // North America
      [
        const Point(70, -165), const Point(70, -100), const Point(60, -60),
        const Point(45, -60), const Point(30, -80), const Point(15, -90),
        const Point(15, -105), const Point(30, -115), const Point(40, -125),
        const Point(60, -140), const Point(65, -165),
      ],
      // South America
      [
        const Point(10, -75), const Point(5, -50), const Point(-10, -35),
        const Point(-25, -45), const Point(-40, -65), const Point(-55, -70),
        const Point(-20, -70), const Point(0, -80),
      ],
      // Eurasia
      [
        const Point(70, -10), const Point(70, 40), const Point(75, 100),
        const Point(65, 170), const Point(50, 140), const Point(35, 120),
        const Point(10, 105), const Point(25, 60), const Point(40, 30),
      ],
      // Africa
      [
        const Point(35, -5), const Point(35, 30), const Point(10, 45),
        const Point(-10, 40), const Point(-35, 20), const Point(0, 10),
      ],
      // Australia
      [
        const Point(-12, 130), const Point(-15, 150), const Point(-35, 150),
        const Point(-38, 140), const Point(-32, 115),
      ],
    ];

    for (var poly in continents) {
      final path = Path();
      bool moved = false;
      for (var pt in poly) {
        Offset? screenPt = project3D(pt.x, pt.y, radius, size);
        if (screenPt != null) {
          if (!moved) {
            path.moveTo(screenPt.dx, screenPt.dy);
            moved = true;
          } else {
            path.lineTo(screenPt.dx, screenPt.dy);
          }
        }
      }
      if (moved) {
        path.close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      }
    }
  }

  void _draw3DFlightArc(Canvas canvas, Size size, double radius, PassengerFlightItem flight, bool isActive) {
    final path = Path();
    bool moved = false;

    int steps = 30;
    for (int i = 0; i <= steps; i++) {
      double t = i / steps;
      double lat = flight.origin.latitude + (flight.destination.latitude - flight.origin.latitude) * t;
      double lon = flight.origin.longitude + (flight.destination.longitude - flight.origin.longitude) * t;

      // Curved 3D Altitude arc outward in space
      double arcAlt = sin(t * pi) * 25.0 * zoomLevel;
      Offset? pt = project3D(lat, lon, radius, size, altOffset: arcAlt);

      if (pt != null) {
        if (!moved) {
          path.moveTo(pt.dx, pt.dy);
          moved = true;
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
    }

    if (moved) {
      final arcPaint = Paint()
        ..color = isActive ? AppColors.skyBlue : AppColors.borderSubtle
        ..strokeWidth = isActive ? 3.5 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, arcPaint);
    }
  }

  void _draw3DAirportPin(Canvas canvas, Size size, double radius, AirportInfo airport, {required bool isOrigin}) {
    Offset? pt = project3D(airport.latitude, airport.longitude, radius, size);
    if (pt == null) return;

    Color color = isOrigin ? AppColors.electricAmber : AppColors.skyBlue;
    canvas.drawCircle(pt, 6 * zoomLevel, Paint()..color = color);
    canvas.drawCircle(pt, 12 * zoomLevel, Paint()..color = color.withValues(alpha: 0.3));
  }

  void _draw3DActivePlane(Canvas canvas, Size size, double radius, PassengerFlightItem flight) {
    double t = flight.progress.clamp(0.0, 1.0);
    double lat = flight.origin.latitude + (flight.destination.latitude - flight.origin.latitude) * t;
    double lon = flight.origin.longitude + (flight.destination.longitude - flight.origin.longitude) * t;

    double arcAlt = sin(t * pi) * 25.0 * zoomLevel;
    Offset? planePt = project3D(lat, lon, radius, size, altOffset: arcAlt + 10);
    if (planePt == null) return;

    // Glowing 3D Aircraft Marker
    canvas.drawCircle(planePt, 18, Paint()..color = AppColors.skyBlue.withValues(alpha: 0.35));
    canvas.drawCircle(planePt, 8, Paint()..color = AppColors.skyBlue);
    canvas.drawCircle(planePt, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant Globe3dPainter oldDelegate) {
    return oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY ||
        oldDelegate.activeFlight.progress != activeFlight.progress ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.isDarkTheme != isDarkTheme;
  }
}
