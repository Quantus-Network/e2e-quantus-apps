import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

const _borderGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x55FFFFFF), Color(0x18FFFFFF)],
);

class GlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool filled;

  const GlassButton({
    super.key,
    this.onTap,
    required this.child,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: CustomPaint(
            painter: RectBorderPainter(
              borderRadius: BorderRadius.circular(radius),
              strokeWidth: 0.889,
              gradient: _borderGradient,
            ),
            child: Container(
              padding: padding,
              color: filled ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
