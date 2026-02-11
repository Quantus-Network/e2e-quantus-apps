import 'dart:ui';
import 'package:flutter/material.dart';

class OutlinedGlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const OutlinedGlassButton({
    super.key,
    this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            inner: ColorFilter.matrix(<double>[
              0.8, 0, 0, 0, 0,
              0, 0.8, 0, 0, 0,
              0, 0, 0.8, 0, 0,
              0, 0, 0, 1, 0,
            ]),
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.44), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class FilledGlassButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FilledGlassButton({
    super.key,
    this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            inner: ColorFilter.matrix(<double>[
              1.05, 0, 0, 0, 0,
              0, 1.05, 0, 0, 0,
              0, 0, 1.05, 0, 0,
              0, 0, 0, 1, 0,
            ]),
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.topCenter,
                stops: [0, 0.01],
                colors: [Color(0x33FFFFFF), Colors.transparent],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
