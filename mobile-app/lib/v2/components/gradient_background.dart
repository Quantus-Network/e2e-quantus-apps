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
          child: CustomPaint(painter: _EllipseGlowPainter(glowColor: colors.backgroundGlow.useOpacity(0.2))),
        ),
        child,
      ],
    );
  }
}

class _EllipseGlowPainter extends CustomPainter {
  static const xOffset = -110.0;
  static const yOffset = -60.0;

  final Color glowColor;

  _EllipseGlowPainter({required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 390.0;
    final sy = size.height / 844.0;
    final ox = xOffset * sx;
    final oy = yOffset * sy;
    final paint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 85);

    canvas.save();
    canvas.translate(176.56 * sx + ox, 77.88 * sy + oy);
    canvas.rotate(30 * pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 66.46 * sx, height: 406.13 * sy), paint);
    canvas.restore();

    canvas.save();
    canvas.translate(367.38 * sx + ox, 41.54 * sy + oy);
    canvas.rotate(30 * pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 33.41 * sx, height: 446.53 * sy), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EllipseGlowPainter oldDelegate) => glowColor != oldDelegate.glowColor;
}
