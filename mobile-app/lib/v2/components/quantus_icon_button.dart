import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

enum IconButtonShape { rounded, circular }

enum IconButtonStyle { glass, flat }

enum IconButtonSize { small, medium }

class QuantusIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final IconButtonSize size;
  final IconButtonShape shape;
  final IconButtonStyle style;
  final bool isDisabled;
  final bool isLoading;
  final bool isActive;
  final double? radius;

  const QuantusIconButton.rounded({
    super.key,
    required this.icon,
    this.size = IconButtonSize.medium,
    this.onTap,
    this.isActive = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.radius,
    this.style = IconButtonStyle.flat,
  }) : shape = IconButtonShape.rounded;

  const QuantusIconButton.circular({
    super.key,
    required this.icon,
    this.size = IconButtonSize.medium,
    this.onTap,
    this.isActive = false,
    this.isLoading = false,
    this.isDisabled = false,
    this.radius,
    this.style = IconButtonStyle.flat,
  }) : shape = IconButtonShape.circular;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null || isLoading || isDisabled;

    final double buttonSize = size == IconButtonSize.small ? 28 : 44;
    final double iconSize = size == IconButtonSize.small ? 16 : 20;

    final double defaultRadius = size == IconButtonSize.small ? 8 : 16;
    final double cornerRadius = radius ?? defaultRadius;
    final Color iconColor = isActive ? context.colors.accentOrange : context.colors.textPrimary;

    final BorderRadius borderRadius;
    switch (shape) {
      case IconButtonShape.rounded:
        borderRadius = BorderRadius.circular(cornerRadius);
        break;
      case IconButtonShape.circular:
        borderRadius = BorderRadius.circular(buttonSize / 2);
        break;
    }

    Widget content = Center(
      child: isLoading
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(color: context.colors.textPrimary, strokeWidth: 1.5),
            )
          : Icon(icon, color: iconColor, size: iconSize),
    );

    switch (style) {
      case IconButtonStyle.glass:
        content = _buildGlassStyle(content, buttonSize: buttonSize, borderRadius: borderRadius);
        break;
      case IconButtonStyle.flat:
        content = _buildFlatStyle(content, buttonSize: buttonSize, borderRadius: borderRadius, colors: context.colors);
        break;
    }

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: borderRadius,
      child: Opacity(opacity: disabled ? 0.9 : 1, child: content),
    );
  }

  Widget _buildFlatStyle(
    Widget child, {
    required double buttonSize,
    required BorderRadius borderRadius,
    required AppColorsV2 colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: BoxBorder.all(color: isActive ? colors.accentOrange.useOpacity(0.2) : colors.borderButton, width: 1),
        borderRadius: borderRadius,
      ),
      child: SizedBox(width: buttonSize, height: buttonSize, child: child),
    );
  }

  Widget _buildGlassStyle(Widget child, {required double buttonSize, required BorderRadius borderRadius}) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          transform: GradientRotation(30 * math.pi / 180),
          colors: [
            Color(0xFF6F6F6F), // 0%
            Color(0xFF1F1F1F), // 25%
            Color(0xFF0E0E0E), // 50%
            Color(0xFF1F1F1F), // 75%
            Color(0xFF6F6F6F), // 100%
          ],
          stops: [0.0, 0.25, 0.50, 0.75, 1.0],
        ),
      ),
      // The padding acts as the border thickness!
      padding: const EdgeInsets.all(0.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          gradient: const LinearGradient(
            transform: GradientRotation(45 * math.pi / 180),
            colors: [Color(0xFF050505), Color(0xFF171717)],
            stops: [0, 1],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: borderRadius, color: const Color.fromRGBO(255, 255, 255, 0.02)),
          child: child,
        ),
      ),
    );
  }
}
