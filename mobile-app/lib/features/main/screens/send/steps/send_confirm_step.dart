import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class SendConfirmStep extends StatelessWidget {
  final BigInt amount;
  final String formattedAmount;
  final String formattedFee;
  final String recipientName;
  final String recipientAddress;
  final String tokenSymbol;
  final bool isReversible;
  final String formattedReversibleTime;
  final String? errorMessage;
  final bool isSending;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  const SendConfirmStep({
    super.key,
    required this.amount,
    required this.formattedAmount,
    required this.formattedFee,
    required this.recipientName,
    required this.recipientAddress,
    required this.tokenSymbol,
    required this.isReversible,
    required this.formattedReversibleTime,
    this.errorMessage,
    required this.isSending,
    required this.onClose,
    required this.onConfirm,
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
                  onTap: onClose,
                  child: SizedBox(
                    width: context.themeSize.overlayCloseIconSize,
                    height: context.themeSize.overlayCloseIconSize,
                    child: Icon(Icons.close, color: Colors.white, size: context.themeSize.overlayCloseIconSize),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Send icon and title
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
              Text('SEND', textAlign: TextAlign.center, style: context.themeText.largeTitle),
            ],
          ),
          const SizedBox(height: 28),

          // Transaction details
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
              const SizedBox(height: 21),

              // Recipient information
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('To:', style: context.themeText.smallParagraph?.copyWith(color: context.themeColors.textMuted)),
                  const SizedBox(height: 12),
                  Text(
                    recipientName,
                    textAlign: TextAlign.center,
                    style: context.themeText.paragraph?.copyWith(color: context.themeColors.checksum),
                  ),
                  const SizedBox(height: 12),
                  Text(recipientAddress, style: context.themeText.tiny),
                ],
              ),

              if (isReversible) const SizedBox(height: 21),
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
          const SizedBox(height: 28),

          // Error message
          if (errorMessage != null)
            SizedBox(
              height: 70,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SingleChildScrollView(
                  child: Text(
                    errorMessage!,
                    style: context.themeText.detail?.copyWith(color: context.themeColors.textError),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          const Spacer(),
          // Network fee and confirm button
          SizedBox(
            width: context.themeSize.sendOverlayContainerWidth,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Network fee', style: context.themeText.detail?.copyWith(fontWeight: FontWeight.w500)),

                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          '$formattedFee $tokenSymbol',
                          style: context.themeText.detail?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        SvgPicture.asset('assets/settings_icon.svg', width: context.isTablet ? 20 : 14),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Button(variant: ButtonVariant.neutral, label: 'Confirm', onPressed: isSending ? null : onConfirm),
              ],
            ),
          ),
          SizedBox(height: context.themeSize.bottomButtonSpacing),
        ],
      ),
    );
  }
}
