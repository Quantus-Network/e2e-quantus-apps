import 'dart:math';
import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.0, -0.487),
                radius: 1.609,
                colors: [colors.backgroundAlt, colors.background],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _EllipseGlowPainter(glowColor: colors.backgroundGlow.useOpacity(0.3))),
        ),
        child,
      ],
    );
  }
}

class _EllipseGlowPainter extends CustomPainter {
  final Color glowColor;

  _EllipseGlowPainter({required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390.0;
    // final sy = size.height / 844.0; // we don't want to be relative on the y axis
    final paint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    const e1x = 95.0;
    const e1y = 3.0;
    const e1width = 86.0;
    const e1height = 528.0;
    const e2x = 330.0;
    const e2y = -48.0;
    const e2width = 44.0;
    const e2height = 580.0;

    canvas.save();
    canvas.translate(e1x * sx, e1y);
    canvas.rotate(30 * pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: e1width * sx, height: e1height), paint);
    canvas.restore();

    canvas.save();
    canvas.translate(e2x * sx, e2y);
    canvas.rotate(30 * pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: e2width * sx, height: e2height), paint);
    canvas.restore();

    // DEBUG: vertical center lines
    // final debugPaint = Paint()
    //   ..color = const Color(0xFFFF0000)
    //   ..strokeWidth = 1;
    // canvas.drawLine(Offset(e1x * sx, 0), Offset(e1x * sx, size.height), debugPaint);
    // debugPaint.color = const Color(0xFF00FF00);
    // canvas.drawLine(Offset(e2x * sx, 0), Offset(e2x * sx, size.height), debugPaint);
  }

  @override
  bool shouldRepaint(_EllipseGlowPainter oldDelegate) => glowColor != oldDelegate.glowColor;
}
