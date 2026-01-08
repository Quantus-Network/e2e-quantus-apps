import 'package:flutter/material.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class SendCompleteStep extends StatelessWidget {
  final String formattedAmount;
  final String recipientName;
  final String recipientAddress;
  final String tokenSymbol;
  final bool isReversible;
  final String formattedReversibleTime;
  final VoidCallback onDone;

  const SendCompleteStep({
    super.key,
    required this.formattedAmount,
    required this.recipientName,
    required this.recipientAddress,
    required this.tokenSymbol,
    required this.isReversible,
    required this.formattedReversibleTime,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Close button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onDone,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Icon(Icons.close, color: Colors.white, size: context.themeSize.overlayCloseIconSize),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Sent icon and title
          Column(
            children: [
              Center(
                child: Image.asset(
                  'assets/transaction/send_icon.png',
                  width: context.isTablet ? 101 : 61,
                  height: context.isTablet ? 92 : 52,
                ),
              ),
              const SizedBox(height: 17),
              Text('SENDING', textAlign: TextAlign.center, style: context.themeText.largeTitle),
            ],
          ),
          const SizedBox(height: 28),

          // Transaction details
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Amount
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: formattedAmount, style: context.themeText.mediumTitle),
                        TextSpan(text: ' $tokenSymbol', style: context.themeText.paragraph),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Recipient information
              Text(
                'will be sent to',
                textAlign: TextAlign.center,
                style: context.themeText.smallParagraph?.copyWith(color: context.themeColors.textMuted),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    child: Text(
                      recipientName,
                      textAlign: TextAlign.center,
                      style: context.themeText.paragraph?.copyWith(color: context.themeColors.checksum),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(recipientAddress, style: context.themeText.tiny),
                ],
              ),

              if (isReversible) const SizedBox(height: 14),
              // Reversible time information
              if (isReversible)
                Container(
                  width: context.themeSize.sendOverlayContainerWidth,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF313131),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      SizedBox(
                        width: context.isTablet ? null : 299,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: 'Reversible for: ', style: context.themeText.smallParagraph),
                              TextSpan(text: formattedReversibleTime, style: context.themeText.detail),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const Spacer(),
          // Done Button
          Button(variant: ButtonVariant.glassOutline, label: 'Done', onPressed: onDone),
          SizedBox(height: context.themeSize.bottomButtonSpacing),
        ],
      ),
    );
  }
}

