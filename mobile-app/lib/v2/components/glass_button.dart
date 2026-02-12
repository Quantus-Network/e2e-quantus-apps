import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool filled;
  final double height;

  const GlassButton({
    super.key,
    this.onTap,
    required this.child,
    required this.height,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer.clearGlass(
        height: height,
        borderRadius: BorderRadius.circular(radius),
        color: filled ? const Color(0xFFFFFFFF).withValues(alpha: 0.1) : Colors.transparent,
        borderColor: const Color(0xFFFFFFFF).withValues(alpha: 0.66),
        borderWidth: 0.889,
        blur: 20,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                    ],
                    stops: const [0.0, 0.25, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            Center(child: child),
          ],
        ),
      ),
    );
  }
}
