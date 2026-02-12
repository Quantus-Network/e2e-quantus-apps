import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool filled;
  final double height;

  GlassButton({
    super.key,
    this.onTap,
    required this.child,
    required this.height,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
    this.filled = false,
  });

  final filledGradient = LinearGradient(colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.04)]);
  final emptyGradient = const LinearGradient(colors: [Colors.transparent, Colors.transparent]);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer.clearGlass(
        height: height,
        borderRadius: BorderRadius.circular(radius),
        gradient: filled ? filledGradient : emptyGradient,
        borderGradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x70FFFFFF), Color(0x18FFFFFF)],
        ),
        borderWidth: 0.889,
        blur: 20,
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
