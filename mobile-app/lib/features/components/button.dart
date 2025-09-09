import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';

/// Enum to define the visual style of the button.
enum ButtonVariant { transparent, neutral, primary, success, danger, glass }

/// A versatile and customizable action button with gradient and variant support.
class Button extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final EdgeInsets? padding;
  final TextStyle? textStyle;
  final ButtonVariant variant;

  /// The main constructor for creating a highly customized button.
  /// It's recommended to use the factory constructors for specific variants.
  const Button({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
    this.padding = const EdgeInsets.all(16),
    this.textStyle,
    this.variant = ButtonVariant.glass,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    // Define a default text style if none is provided.
    final effectiveTextStyle = textStyle ?? context.themeText.paragraph!;

    final buttonContent = Center(
      child: isLoading
          ? SizedBox(
              width: (effectiveTextStyle.fontSize ?? 16) + 6,
              height: (effectiveTextStyle.fontSize ?? 16) + 6,
              child: CircularProgressIndicator(
                color: context.themeColors.background,
                strokeWidth: 2.0,
              ),
            )
          : Text(label, style: effectiveTextStyle),
    );

    Widget buttonWidget;

    switch (variant) {
      case ButtonVariant.primary:
        buttonWidget = Container(
          width: width,
          padding: padding,
          decoration: ShapeDecoration(
            // Use the provided gradient
            gradient: LinearGradient(
              begin: const Alignment(0.00, -1.00),
              end: const Alignment(0, 1),
              colors: context.themeColors.buttonPrimary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: buttonContent,
        );
        break;

      case ButtonVariant.transparent:
        buttonWidget = Container(
          width: width,
          padding: padding,
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: buttonContent,
        );
        break;

      case ButtonVariant.neutral:
        buttonWidget = Container(
          width: width,
          padding: padding,
          decoration: ShapeDecoration(
            color: context.themeColors.buttonNeutral,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: buttonContent,
        );
        break;

      case ButtonVariant.danger:
        buttonWidget = Container(
          width: width,
          padding: padding,
          decoration: ShapeDecoration(
            color: context.themeColors.buttonDanger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: buttonContent,
        );
        break;

      case ButtonVariant.success:
        buttonWidget = Container(
          width: width,
          padding: padding,
          decoration: ShapeDecoration(
            color: context.themeColors.buttonSuccess,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          child: buttonContent,
        );
        break;

      default:
        buttonWidget = ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: width,
              padding: padding,
              decoration: ShapeDecoration(
                color: context.themeColors.buttonGlass,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: buttonContent,
            ),
          ),
        );
        break;
    }

    return GestureDetector(
      onTap: isDisabled ? null : onPressed,
      child: buttonWidget,
    );
  }
}
