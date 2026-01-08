import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/services/hardware_wallet_service.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class HardwareSignStep extends ConsumerWidget {
  final UnsignedTransactionData? unsignedData;
  final VoidCallback onClose;
  final VoidCallback onNext;

  const HardwareSignStep({
    super.key,
    required this.unsignedData,
    required this.onClose,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          // Hardware wallet icon and title
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
              Text('Scan with Keystone Wallet', textAlign: TextAlign.center, style: context.themeText.largeTitle),
            ],
          ),
          const SizedBox(height: 28),

          if (unsignedData == null)
            SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator(color: context.themeColors.primary)),
            )
          else
            Container(
              width: context.isTablet ? 300 : 250,
              height: context.isTablet ? 300 : 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Builder(
                builder: (context) {
                  final hwService = ref.read(hardwareWalletServiceProvider);
                  final qrData = hwService.encodePayloadAsUr(unsignedData!.encodedPayloadRaw);
                  print('QR Code payload: $qrData');
                  return QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: double.infinity,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  );
                },
              ),
            ),

          const Spacer(),
          // Continue button
          SizedBox(
            width: context.themeSize.sendOverlayContainerWidth,
            child: Button(
              variant: ButtonVariant.neutral,
              label: 'Next',
              onPressed: unsignedData == null ? null : onNext,
            ),
          ),
          SizedBox(height: context.themeSize.bottomButtonSpacing),
        ],
      ),
    );
  }
}
