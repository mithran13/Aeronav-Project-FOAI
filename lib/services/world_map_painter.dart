import 'dart:math';
import 'package:flutter/material.dart';
import '../models/flight_item.dart';
import '../theme/app_colors.dart';

class WorldMapPainter extends CustomPainter {
  final PassengerFlightItem activeFlight;
  final List<PassengerFlightItem> allFlights;
  final double zoomLevel;
  final Offset mapOffset;
  final bool showCityLabels;
  final bool isDarkTheme;

  WorldMapPainter({
    required this.activeFlight,
    required this.allFlights,
    required this.zoomLevel,
    required this.mapOffset,
    this.showCityLabels = true,
    this.isDarkTheme = true,
  });

  // World latitude (-90 to 90) & longitude (-180 to 180) to canvas offset projection
  Offset project(double lat, double lon, Size size) {
    final center = Offset(size.width / 2, size.height / 2) + mapOffset;
    double x = (lon / 180.0) * (size.width * 0.45 * zoomLevel);
    double y = -(lat / 90.0) * (size.height * 0.45 * zoomLevel);
    return center + Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = isDarkTheme ? AppColors.spaceNavy : AppColors.lightBg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 1. Draw Lat/Lon Graticule Lines (Equator, Tropics, Prime Meridian)
    final gridPaint = Paint()
      ..color = (isDarkTheme ? AppColors.skyBlue : AppColors.electricBlue).withValues(alpha: 0.12)
      ..strokeWidth = 1.0;

    for (double lat = -60; lat <= 60; lat += 30) {
      Offset p1 = project(lat, -180, size);
      Offset p2 = project(lat, 180, size);
      canvas.drawLine(p1, p2, gridPaint);
    }
    for (double lon = -150; lon <= 150; lon += 30) {
      Offset p1 = project(80, lon, size);
      Offset p2 = project(-80, lon, size);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // 2. Draw Realistic Vector Continent Outlines
    final landPaint = Paint()
      ..color = isDarkTheme ? AppColors.cardBg : AppColors.lightBorder
      ..style = PaintingStyle.fill;

    final landBorderPaint = Paint()
      ..color = isDarkTheme ? AppColors.surfaceOverlay : const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    _drawContinents(canvas, size, landPaint, landBorderPaint);

    // 3. Draw All Tracked Flight Paths (Background & Active)
    for (var flight in allFlights) {
      bool isActive = flight.id == activeFlight.id;
      _drawFlightArcPath(canvas, size, flight, isActive);
    }

    // 4. Draw Major Airport City Pins & Labels
    _drawAirportPin(canvas, size, activeFlight.origin, isOrigin: true);
    _drawAirportPin(canvas, size, activeFlight.destination, isOrigin: false);

    // 5. Draw Animated Active Airplane Position Marker
    _drawActivePlaneMarker(canvas, size, activeFlight);
  }

  void _drawContinents(Canvas canvas, Size size, Paint fillPaint, Paint strokePaint) {
    // North America
    _drawPolygon(canvas, size, fillPaint, strokePaint, [
      const Point(70, -165), const Point(70, -100), const Point(60, -60),
      const Point(45, -60), const Point(30, -80), const Point(25, -80),
      const Point(15, -90), const Point(15, -105), const Point(30, -115),
      const Point(40, -125), const Point(60, -140), const Point(65, -165),
    ]);

    // South America
    _drawPolygon(canvas, size, fillPaint, strokePaint, [
      const Point(10, -75), const Point(5, -50), const Point(-10, -35),
      const Point(-25, -45), const Point(-40, -65), const Point(-55, -70),
      const Point(-45, -75), const Point(-20, -70), const Point(0, -80),
    ]);

    // Eurasia
    _drawPolygon(canvas, size, fillPaint, strokePaint, [
      const Point(70, -10), const Point(70, 40), const Point(75, 100),
      const Point(65, 170), const Point(50, 140), const Point(35, 120),
      const Point(25, 120), const Point(10, 105), const Point(10, 75),
      const Point(25, 60), const Point(30, 35), const Point(40, 30),
      const Point(45, 15), const Point(55, 10), const Point(60, 5),
    ]);

    // Africa
    _drawPolygon(canvas, size, fillPaint, strokePaint, [
      const Point(35, -5), const Point(35, 30), const Point(10, 45),
      const Point(-10, 40), const Point(-35, 20), const Point(-35, 18),
      const Point(0, 10), const Point(5, -5), const Point(15, -15),
    ]);

    // Australia
    _drawPolygon(canvas, size, fillPaint, strokePaint, [
      const Point(-12, 130), const Point(-15, 150), const Point(-35, 150),
      const Point(-38, 140), const Point(-32, 115), const Point(-20, 115),
    ]);
  }

  void _drawPolygon(Canvas canvas, Size size, Paint fill, Paint stroke, List<Point<double>> points) {
    if (points.length < 3) return;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      Offset pt = project(points[i].x, points[i].y, size);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawFlightArcPath(Canvas canvas, Size size, PassengerFlightItem flight, bool isActive) {
    Offset start = project(flight.origin.latitude, flight.origin.longitude, size);
    Offset end = project(flight.destination.latitude, flight.destination.longitude, size);

    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double len = sqrt(dx * dx + dy * dy);

    double arcHeight = min(len * 0.25, 80.0 * zoomLevel);
    Offset mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - arcHeight);

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);

    final linePaint = Paint()
      ..color = isActive
          ? AppColors.electricBlue
          : (isDarkTheme ? AppColors.borderSubtle : const Color(0xFFCBD5E1))
      ..strokeWidth = isActive ? 3.5 : 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  void _drawAirportPin(Canvas canvas, Size size, AirportInfo airport, {required bool isOrigin}) {
    Offset pt = project(airport.latitude, airport.longitude, size);
    Color pinColor = isOrigin ? AppColors.electricAmber : AppColors.electricBlue;

    canvas.drawCircle(pt, 10, Paint()..color = pinColor.withValues(alpha: 0.25));
    canvas.drawCircle(pt, 5, Paint()..color = pinColor);

    if (showCityLabels) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${airport.city} (${airport.iata})',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : AppColors.lightText,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: isDarkTheme ? const [Shadow(color: Colors.black, blurRadius: 4)] : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, pt + const Offset(12, -8));
    }
  }

  void _drawActivePlaneMarker(Canvas canvas, Size size, PassengerFlightItem flight) {
    Offset start = project(flight.origin.latitude, flight.origin.longitude, size);
    Offset end = project(flight.destination.latitude, flight.destination.longitude, size);

    double dx = end.dx - start.dx;
    double dy = end.dy - start.dy;
    double len = sqrt(dx * dx + dy * dy);
    double arcHeight = min(len * 0.25, 80.0 * zoomLevel);
    Offset mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - arcHeight);

    double t = flight.progress.clamp(0.0, 1.0);
    double u = 1 - t;
    double px = u * u * start.dx + 2 * u * t * mid.dx + t * t * end.dx;
    double py = u * u * start.dy + 2 * u * t * mid.dy + t * t * end.dy;
    Offset planePt = Offset(px, py);

    double tx = 2 * u * (mid.dx - start.dx) + 2 * t * (end.dx - mid.dx);
    double ty = 2 * u * (mid.dy - start.dy) + 2 * t * (end.dy - mid.dy);
    double angle = atan2(ty, tx);

    // Glowing aura circle around active plane
    canvas.drawCircle(planePt, 18, Paint()..color = AppColors.skyBlue.withValues(alpha: 0.3));

    canvas.save();
    canvas.translate(planePt.dx, planePt.dy);
    canvas.rotate(angle + pi / 2);

    Path planeIcon = Path()
      ..moveTo(0, -12)
      ..lineTo(3, -3)
      ..lineTo(12, 3)
      ..lineTo(12, 6)
      ..lineTo(2, 3)
      ..lineTo(2, 10)
      ..lineTo(5, 12)
      ..lineTo(5, 14)
      ..lineTo(0, 12)
      ..lineTo(-5, 14)
      ..lineTo(-5, 12)
      ..lineTo(-2, 10)
      ..lineTo(-2, 3)
      ..lineTo(-12, 6)
      ..lineTo(-12, 3)
      ..lineTo(-3, -3)
      ..close();

    canvas.drawPath(planeIcon, Paint()..color = AppColors.skyBlue);
    canvas.drawPath(planeIcon, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.0);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) {
    return oldDelegate.activeFlight.progress != activeFlight.progress ||
        oldDelegate.zoomLevel != zoomLevel ||
        oldDelegate.mapOffset != mapOffset ||
        oldDelegate.isDarkTheme != isDarkTheme;
  }
}
