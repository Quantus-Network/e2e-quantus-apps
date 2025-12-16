import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:resonance_network_wallet/features/components/button.dart';
import 'package:resonance_network_wallet/features/components/scaffold_base.dart';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class TransactionQRDisplayScreen extends StatelessWidget {
  const TransactionQRDisplayScreen({super.key, required this.payloadToSign});

  final List<int> payloadToSign;

  @override
  Widget build(BuildContext context) {
    final hexPayload = '0x${hex.encode(payloadToSign)}';

    return ScaffoldBase(
      appBar: WalletAppBar(title: 'Sign Transaction'),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Please scan with Keystone Wallet',
                    style: context.themeText.smallTitle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: context.isTablet ? 300 : 250,
                    height: context.isTablet ? 300 : 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: QrImageView(
                      data: hexPayload,
                      version: QrVersions.auto,
                      size: double.infinity,
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Scan this QR code with your Keystone hardware wallet to sign the transaction.',
                      style: context.themeText.smallParagraph?.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Button(
            variant: ButtonVariant.primary,
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          SizedBox(height: context.themeSize.bottomButtonSpacing),
        ],
      ),
    );
  }
}
