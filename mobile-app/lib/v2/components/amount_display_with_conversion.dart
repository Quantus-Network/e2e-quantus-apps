import 'package:flutter/material.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/providers/currency_display_provider.dart';
import 'package:resonance_network_wallet/v2/components/quantus_icon_button.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class AmountDisplayWithConversion extends StatelessWidget {
  final CurrencyDisplayState amountDisplay;
  final VoidCallback? onFlip;
  final CrossAxisAlignment alignment;
  final bool colorizeAmount;

  const AmountDisplayWithConversion({
    super.key,
    required this.amountDisplay,
    this.onFlip,
    this.alignment = CrossAxisAlignment.center,
    this.colorizeAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.themeText;
    final colors = context.colors;
    final primaryAmountColor = colorizeAmount ? colors.success : colors.textPrimary;

    final MainAxisAlignment mainAxisAlignment = switch (alignment) {
      CrossAxisAlignment.center => MainAxisAlignment.center,
      _ => MainAxisAlignment.start,
    };

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: amountDisplay.primaryAmount,
                style: text.extraLargeTitle?.copyWith(fontFamily: AppTextTheme.fontFamily, color: primaryAmountColor),
              ),
              if (!amountDisplay.isFlipped) ...[
                const TextSpan(text: '     '),
                TextSpan(
                  text: AppConstants.tokenSymbol,
                  style: text.mediumTitle?.copyWith(
                    fontFamily: AppTextTheme.fontFamilySecondary,
                    color: primaryAmountColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: mainAxisAlignment,
          children: [
            Text(
              '≈ ${amountDisplay.secondaryAmount}',
              style: text.paragraph?.copyWith(
                color: colors.textSecondary,
                fontFamily: AppTextTheme.fontFamilySecondary,
              ),
            ),
            if (onFlip != null) ...[
              const SizedBox(width: 8),
              QuantusIconButton.circular(
                icon: Icons.swap_vert,
                onTap: onFlip,
                isActive: amountDisplay.isFlipped,
                size: IconButtonSize.small,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
