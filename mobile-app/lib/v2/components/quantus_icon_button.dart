import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';

enum IconButtonShape { rounded, circular }

enum IconButtonSize { small, medium }

class QuantusIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final IconButtonSize size;
  final IconButtonShape shape;
  final bool isDisabled;
  final bool isLoading;
  final bool isActive;

  const QuantusIconButton.rounded({
    super.key,
    required this.icon,
    this.size = IconButtonSize.medium,
    this.onTap,
    this.isActive = false,
    this.isLoading = false,
    this.isDisabled = false,
  }) : shape = IconButtonShape.rounded;

  const QuantusIconButton.circular({
    super.key,
    required this.icon,
    this.size = IconButtonSize.medium,
    this.onTap,
    this.isActive = false,
    this.isLoading = false,
    this.isDisabled = false,
  }) : shape = IconButtonShape.circular;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null || isLoading || isDisabled;

    final double buttonSize = size == IconButtonSize.small ? 24 : 40;
    final double iconSize = size == IconButtonSize.small ? 12 : 20;
    final double radius = size == IconButtonSize.small ? 6 : 14;

    final buttonContent = Center(
      child: isLoading
          ? SizedBox(
              width: buttonSize + 6,
              height: buttonSize + 6,
              child: CircularProgressIndicator(color: context.colors.textPrimary, strokeWidth: 2.0),
            )
          : SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: Icon(
                icon,
                color: isActive ? context.colors.accentOrange : context.colors.textPrimary,
                size: iconSize,
              ),
            ),
    );

    final BorderRadius borderRadius;
    switch (shape) {
      case IconButtonShape.rounded:
        borderRadius = BorderRadius.circular(radius);
        break;

      case IconButtonShape.circular:
        borderRadius = BorderRadius.circular(100);
        break;
    }

    return InkWell(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.9 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.background,
            border: BoxBorder.all(
              color: isActive ? context.colors.accentOrange.useOpacity(0.2) : context.colors.borderButton,
              width: 1,
            ),
            borderRadius: borderRadius,
          ),
          child: SizedBox(width: buttonSize, height: buttonSize, child: buttonContent),
        ),
      ),
    );
  }
}
