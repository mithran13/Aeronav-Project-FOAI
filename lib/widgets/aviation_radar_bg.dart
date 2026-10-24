import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AviationRadarBackgroundWidget extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const AviationRadarBackgroundWidget({
    super.key,
    required this.child,
    this.isDark = true,
  });

  @override
  State<AviationRadarBackgroundWidget> createState() => _AviationRadarBackgroundWidgetState();
}

class _AviationRadarBackgroundWidgetState extends State<AviationRadarBackgroundWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // GPU-Accelerated Background Radar & Grid Animation
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _RadarBackgroundPainter(
                    angle: _controller.value * 2 * pi,
                    isDark: widget.isDark,
                  ),
                );
              },
            ),
          ),
        ),

        // Foreground Content
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

class _RadarBackgroundPainter extends CustomPainter {
  final double angle;
  final bool isDark;

  _RadarBackgroundPainter({required this.angle, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.75, size.height * 0.5);
    final maxRadius = max(size.width, size.height) * 0.7;

    final gridPaint = Paint()
      ..color = (isDark ? AppColors.electricBlue : AppColors.royalBlue).withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final ringPaint = Paint()
      ..color = (isDark ? AppColors.electricBlue : AppColors.royalBlue).withValues(alpha: 0.07)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // 1. Draw Distance Concentric Rings
    for (double r = maxRadius * 0.2; r <= maxRadius; r += maxRadius * 0.2) {
      canvas.drawCircle(center, r, ringPaint);
    }

    // 2. Draw Latitude / Longitude Aerospace Grid Lines
    const step = 80.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Draw Rotating Radar Sweep Beam Arc
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: pi * 0.5,
        colors: [
          (isDark ? AppColors.electricAmber : AppColors.royalBlue).withValues(alpha: 0.12),
          Colors.transparent,
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // 4. Draw Rotating Radar Line
    final lineEnd = Offset(
      center.dx + maxRadius * cos(angle),
      center.dy + maxRadius * sin(angle),
    );

    final linePaint = Paint()
      ..color = (isDark ? AppColors.electricAmber : AppColors.royalBlue).withValues(alpha: 0.25)
      ..strokeWidth = 1.5;

    canvas.drawLine(center, lineEnd, linePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarBackgroundPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.isDark != isDark;
  }
}
