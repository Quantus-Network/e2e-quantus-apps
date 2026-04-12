import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

enum ButtonVariant { transparent, primary, secondary, danger, success }

enum IconPlacement { leading, trailing, top }

class QuantusButton extends StatelessWidget {
  final Widget? child;
  final String? _label;
  final Widget? _icon;
  final IconPlacement _iconPlacement;
  final TextStyle? _textStyle;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? width;
  final EdgeInsets padding;
  final ButtonVariant variant;
  final bool isDisabled;
  final double borderRadius;
  final bool centered;

  static const double defaultBorderRadius = 14.0;
  static const double buttonFontSize = 16.0;

  const QuantusButton({
    super.key,
    required Widget this.child,
    this.onTap,
    this.isLoading = false,
    this.width = double.infinity,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.variant = ButtonVariant.primary,
    this.isDisabled = false,
    this.borderRadius = defaultBorderRadius,
    this.centered = true,
  }) : _label = null,
       _icon = null,
       _iconPlacement = IconPlacement.trailing,
       _textStyle = null;

  // this is a simple button with a label and an icon
  const QuantusButton.simple({
    super.key,
    required String label,
    Widget? icon,
    IconPlacement iconPlacement = IconPlacement.trailing,
    this.onTap,
    this.isLoading = false,
    this.width = double.infinity,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
    TextStyle? textStyle,
    this.variant = ButtonVariant.primary,
    this.isDisabled = false,
    this.borderRadius = defaultBorderRadius,
    this.centered = true,
  }) : _label = label,
       _icon = icon,
       _iconPlacement = iconPlacement,
       _textStyle = textStyle,
       child = null;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null || isLoading || isDisabled;
    final visibility = disabled ? 0.25 : 1.0;
    final buttonContent = _buildContent(context, variant: variant);
    final borderRadius = BorderRadius.circular(this.borderRadius);
    final decorationShape = RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: variant == ButtonVariant.secondary
          ? BorderSide(color: context.colors.borderButton, width: 1)
          : BorderSide.none,
    );

    final Color buttonDecorationColor;

    switch (variant) {
      case ButtonVariant.primary:
        buttonDecorationColor = context.colors.accentOrange;
        break;

      case ButtonVariant.secondary:
        buttonDecorationColor = context.colors.sheetBackground;
        break;

      case ButtonVariant.danger:
        buttonDecorationColor = context.colors.buttonDanger;
        break;

      case ButtonVariant.success:
        buttonDecorationColor = context.colors.success;
        break;

      case ButtonVariant.transparent:
        buttonDecorationColor = Colors.transparent;
        break;
    }

    return InkWell(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: visibility,
        child: Container(
          width: width,
          padding: padding,
          decoration: ShapeDecoration(color: buttonDecorationColor, shape: decorationShape),
          child: buttonContent,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {variant = ButtonVariant.primary}) {
    final textColor = switch (variant) {
      ButtonVariant.primary => context.colors.background,
      ButtonVariant.secondary => context.colors.textPrimary,
      ButtonVariant.danger => context.colors.textPrimary,
      ButtonVariant.transparent => context.colors.textPrimary,
      _ => context.colors.textPrimary,
    };

    if (isLoading) {
      final size = (_textStyle?.fontSize ?? buttonFontSize) + 6;
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(color: textColor, strokeWidth: 2.0),
        ),
      );
    }

    if (child != null) return child!;

    final effectiveTextStyle =
        _textStyle ??
        context.themeText.paragraph!.copyWith(fontSize: buttonFontSize, color: textColor, fontWeight: FontWeight.w500);

    Widget content;
    if (_iconPlacement == IconPlacement.top) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          ?_icon,
          Text(_label!, style: effectiveTextStyle),
        ],
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          if (_iconPlacement == IconPlacement.leading && _icon != null) _icon,
          Text(_label!, style: effectiveTextStyle),
          if (_iconPlacement == IconPlacement.trailing && _icon != null) _icon,
        ],
      );
    }

    return Center(child: content);
  }
}
