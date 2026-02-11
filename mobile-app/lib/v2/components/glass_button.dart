import 'dart:ui';
import 'package:flutter/material.dart';

class OutlinedGlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const OutlinedGlassButton({
    super.key,
    this.onTap,
    required this.child,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            inner: const ColorFilter.matrix(<double>[
              0.8, 0, 0, 0, 0,
              0, 0.8, 0, 0, 0,
              0, 0, 0.8, 0, 0,
              0, 0, 0, 1, 0,
            ]),
          ),
          child: CustomPaint(
            painter: _ShimmerBorderPainter(radius: radius),
            child: Container(
              padding: padding,
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.03, 0.97, 1],
                  colors: [Color(0x1AFFFFFF), Colors.transparent, Colors.transparent, Color(0x0D000000)],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBorderPainter extends CustomPainter {
  final double radius;
  _ShimmerBorderPainter({required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.5), Radius.circular(radius));

    final shimmer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = const RadialGradient(
        center: Alignment.topCenter,
        radius: 1.8,
        colors: [Color(0x55FFFFFF), Color(0x18FFFFFF)],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
    canvas.drawRRect(rrect, shimmer);

    final crisp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.889
      ..shader = const RadialGradient(
        center: Alignment.topCenter,
        radius: 1.8,
        colors: [Color(0x66FFFFFF), Color(0x28FFFFFF)],
      ).createShader(rect);
    canvas.drawRRect(rrect, crisp);
  }

  @override
  bool shouldRepaint(covariant _ShimmerBorderPainter old) => old.radius != radius;
}

class FilledGlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const FilledGlassButton({
    super.key,
    this.onTap,
    required this.child,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            inner: const ColorFilter.matrix(<double>[
              1.05, 0, 0, 0, 0,
              0, 1.05, 0, 0, 0,
              0, 0, 1.05, 0, 0,
              0, 0, 0, 1, 0,
            ]),
          ),
          child: CustomPaint(
            painter: _ShimmerBorderPainter(radius: radius),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(radius),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.03, 0.97, 1],
                  colors: [Color(0x1AFFFFFF), Colors.transparent, Colors.transparent, Color(0x0D000000)],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
