import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class ActionButton extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final Color borderColor;
  final VoidCallback onPressed;
  final bool disabled;

  const ActionButton({
    super.key,
    required this.iconWidget,
    required this.label,
    required this.borderColor,
    required this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = disabled ? Colors.white.useOpacity(0.5) : Colors.white;
    final bgColor = Colors.black;
    final effectiveBorderColor = disabled
        ? borderColor.useOpacity(0.5)
        : borderColor;

    Widget finalIconWidget = iconWidget;
    if (iconWidget is SvgPicture) {
      finalIconWidget = SvgPicture.asset(
        ((iconWidget as SvgPicture).bytesLoader as SvgAssetLoader).assetName,
        width: context.themeSize.mainMenuWidth,
        height: context.themeSize.mainMenuHeight,
      );
    } else if (iconWidget is Icon) {
      finalIconWidget = Icon(
        (iconWidget as Icon).icon,
        color: color,
        size: context.themeSize.mainMenuHeight,
      );
    } else if (iconWidget is Image) {
      finalIconWidget = SizedBox(
        width: context.themeSize.mainMenuWidth,
        height: context.themeSize.mainMenuHeight,
        child: iconWidget,
      );
    }

    return Opacity(
      opacity: disabled ? 0.7 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: context.isTablet ? 105 : 65,
          height: context.isTablet ? 96 : 56,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1,
              colors: [effectiveBorderColor, const Color(0x26FFFFFF)],
              stops: [0, 1],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                finalIconWidget,
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: context.themeText.tag,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
