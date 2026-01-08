import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/styles/app_colors_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_size_theme.dart';
import 'package:resonance_network_wallet/features/styles/app_text_theme.dart';
import 'package:resonance_network_wallet/services/hardware_wallet_service.dart';
import 'package:resonance_network_wallet/shared/extensions/media_query_data_extension.dart';

class HardwareScanStep extends ConsumerStatefulWidget {
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final Function(List<String>) onSignatureScanned;
  final VoidCallback? onSimulate;
  final bool showDebugButton;

  const HardwareScanStep({
    super.key,
    required this.isSubmitting,
    this.errorMessage,
    required this.onClose,
    required this.onBack,
    required this.onSignatureScanned,
    this.onSimulate,
    this.showDebugButton = false,
  });

  @override
  ConsumerState<HardwareScanStep> createState() => _HardwareScanStepState();
}

class _HardwareScanStepState extends ConsumerState<HardwareScanStep> {
  final MobileScannerController _signatureScannerController = MobileScannerController();
  final Set<String> _collectedUrParts = {};
  bool _hasScannedSignature = false;

  @override
  void dispose() {
    _signatureScannerController.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_hasScannedSignature || widget.isSubmitting) {
      return;
    }

    final hwService = ref.read(hardwareWalletServiceProvider);

    for (final barcode in capture.barcodes) {
      final v = barcode.rawValue;
      if (v == null) {
        continue;
      }

      if (v.startsWith('UR:')) {
        final wasNew = _collectedUrParts.add(v);

        if (wasNew) {
          // final total = hwService.getTotalFragmentCount(_collectedUrParts.toList());
          // debugPrint('QR Scanner: Total fragments: $total');
          setState(() {});

          final isComplete = hwService.isComplete(_collectedUrParts.toList());
          if (isComplete) {
            _hasScannedSignature = true;
            widget.onSignatureScanned(_collectedUrParts.toList());
          }
        }
      }
      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back + close
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: SizedBox(
                    width: context.themeSize.overlayCloseIconSize,
                    height: context.themeSize.overlayCloseIconSize,
                    child: Icon(Icons.arrow_back, color: Colors.white, size: context.themeSize.overlayCloseIconSize),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
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
              Text('SCAN SIGNATURE', textAlign: TextAlign.center, style: context.themeText.largeTitle),
            ],
          ),
          const SizedBox(height: 28),

          if (widget.isSubmitting)
            SizedBox(
              height: 320,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: context.themeColors.primary),
                    const SizedBox(height: 16),
                    Text('Submitting...', style: context.themeText.paragraph),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 320,
              child: Stack(
                children: [
                  MobileScanner(controller: _signatureScannerController, onDetect: _handleDetect),
                  Container(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF0CE6ED), width: 2),
                      ),
                    ),
                    margin: const EdgeInsets.all(50),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_collectedUrParts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              () {
                                final scanned = _collectedUrParts.length;
                                final hwService = ref.read(hardwareWalletServiceProvider);
                                final total = hwService.getTotalFragmentCount(_collectedUrParts.toList());
                                if (total != null) {
                                  return 'Scanned $scanned of $total fragments';
                                }
                                return 'Scanned $scanned fragment${scanned == 1 ? '' : 's'}...';
                              }(),
                              textAlign: TextAlign.center,
                              style: context.themeText.paragraph?.copyWith(
                                color: context.themeColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          _collectedUrParts.isEmpty
                              ? 'Position the QR code within the frame'
                              : 'Keep scanning until all parts are collected',
                          textAlign: TextAlign.center,
                          style: context.themeText.paragraph?.copyWith(
                            color: context.themeColors.textPrimary.useOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showDebugButton && widget.onSimulate != null)
                    Positioned(
                      bottom: 56,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: TextButton(
                          onPressed: widget.onSimulate,
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
            ),

          const Spacer(),
          if (widget.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                widget.errorMessage!,
                style: context.themeText.detail?.copyWith(color: context.themeColors.textError),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: context.themeSize.bottomButtonSpacing),
        ],
      ),
    );
  }
}
