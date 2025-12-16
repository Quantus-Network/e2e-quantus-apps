import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:convert/convert.dart';
import 'package:quantus_sdk/quantus_sdk.dart' as crypto;
import 'dart:typed_data';
import 'package:resonance_network_wallet/features/components/wallet_app_bar.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

class QRScannerScreen extends StatefulWidget {
  final List<int>? payloadToSign; // Optional payload for debug simulation
  const QRScannerScreen({super.key, this.payloadToSign});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _hasScanned = false; // Add flag to track if we've already scanned

  Future<void> _simulateHardwareSignature() async {
    if (widget.payloadToSign == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No payload provided for simulation')));
      return;
    }

    try {
      // 1. Get the current active account's wallet to sign (simulate hardware wallet)
      final account = (await SettingsService().getActiveAccount())!;
      // For debug simulation, we assume we can get the keypair of the current account
      // This will fail if the current account is actually a hardware wallet without a local key
      // But for testing the flow with a local account pretending to be hardware, this is what we want.
      final debugWallet = await account.getKeypair();

      // 2. Sign the payload using the debug wallet
      // We use signMessage which returns the raw signature
      final signature = crypto.signMessage(keypair: debugWallet, message: widget.payloadToSign!);

      // 3. Combine signature and public key (this is what the hardware wallet should return)
      final signatureWithPublicKey = Uint8List(signature.length + debugWallet.publicKey.length);
      signatureWithPublicKey.setAll(0, signature);
      signatureWithPublicKey.setAll(signature.length, debugWallet.publicKey);

      // 4. Encode as hex string (simulating QR code content)
      final hexSignature = '0x${hex.encode(signatureWithPublicKey)}';

      print('Simulated Hardware Signature: $hexSignature');

      // 5. Return the result as if it was scanned
      if (mounted) {
        Navigator.pop(context, hexSignature);
      }
    } catch (e) {
      print('Simulation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Simulation failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: WalletAppBar(
        title: 'Scan QR Code',
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              return IconButton(
                color: Colors.white,
                icon: Icon(switch (state.torchState) {
                  TorchState.off => Icons.flash_off,
                  TorchState.on => Icons.flash_on,
                  TorchState.auto => Icons.flash_auto,
                  TorchState.unavailable => Icons.flash_off,
                }),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              return IconButton(
                color: Colors.white,
                icon: Icon(switch (state.cameraDirection) {
                  CameraFacing.front => Icons.camera_front,
                  CameraFacing.back => Icons.camera_rear,
                  CameraFacing.external => Icons.camera,
                  CameraFacing.unknown => Icons.camera,
                }),
                onPressed: () => controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_hasScanned) return; // Skip if we've already scanned

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _hasScanned = true; // Set flag before popping
                  print('Popping QR scanner with: ${barcode.rawValue}');
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
          // Overlay with a centered scanning area
          Container(
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF0CE6ED), width: 2),
              ),
            ),
            margin: const EdgeInsets.all(50),
          ),
          // Scanning hint text
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Text(
              'Position the QR code within the frame',
              textAlign: TextAlign.center,
              style: context.themeText.paragraph?.copyWith(color: context.themeColors.textPrimary.useOpacity(0.8)),
            ),
          ),

          // Debug Simulation Button (Only visible in debug mode or if payload is provided)
          if (widget.payloadToSign != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton(
                  onPressed: _simulateHardwareSignature,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.useOpacity(0.7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('DEBUG: SIMULATE SIGNATURE'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
