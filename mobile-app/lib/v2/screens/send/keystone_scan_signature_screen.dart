import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/l10n/app_localizations.dart';
import 'package:resonance_network_wallet/providers/l10n_provider.dart';
import 'package:resonance_network_wallet/services/telemetry_service.dart';
import 'package:resonance_network_wallet/services/transaction_submission_service.dart';
import 'package:resonance_network_wallet/shared/utils/print.dart';
import 'package:resonance_network_wallet/shared/utils/url_utils.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/quantus_icon_button.dart';
import 'package:resonance_network_wallet/v2/screens/send/keystone_sign_cache.dart';
import 'package:resonance_network_wallet/v2/screens/send/send_strategy.dart';
import 'package:resonance_network_wallet/v2/screens/send/send_terminal_screen.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

/// Scans the multi-part (animated) UR signature QR from the Keystone device,
/// accumulating frames until the UR is complete, then decodes it into the raw
/// signature + public key, rebuilds the extrinsic and broadcasts it.
class KeystoneScanSignatureScreen extends ConsumerStatefulWidget {
  final Account account;
  final UnsignedTransactionData unsignedData;
  final String recipientAddress;
  final BigInt amount;
  final BigInt networkFee;
  final int blockHeight;
  final String recipientChecksum;
  final bool isPayMode;
  final SendTerminalContent terminal;

  const KeystoneScanSignatureScreen({
    super.key,
    required this.account,
    required this.unsignedData,
    required this.recipientAddress,
    required this.amount,
    required this.networkFee,
    required this.blockHeight,
    required this.recipientChecksum,
    required this.terminal,
    this.isPayMode = false,
  });

  @override
  ConsumerState<KeystoneScanSignatureScreen> createState() => _KeystoneScanSignatureScreenState();
}

class _KeystoneScanSignatureScreenState extends ConsumerState<KeystoneScanSignatureScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final Set<String> _parts = {};
  final Set<int> _seenSeq = {};
  final RegExp _seqPattern = RegExp(r'/(\d+)-(\d+)/');

  int? _expectedParts;
  bool _done = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || !code.toLowerCase().startsWith('ur:')) return;
    if (!_parts.add(code)) return; // already seen this exact frame

    final match = _seqPattern.firstMatch(code);
    if (match != null) {
      _seenSeq.add(int.parse(match.group(1)!));
      _expectedParts = int.parse(match.group(2)!);
    }

    final parts = _parts.toList();
    if (!isCompleteUr(urParts: parts)) {
      setState(() {});
      return;
    }

    _done = true;
    _controller.stop();
    _submit(parts);
  }

  Future<void> _submit(List<String> parts) async {
    setState(() => _submitting = true);
    try {
      final bytes = decodeUr(urParts: parts);
      final sigSize = signatureBytes().toInt();
      final expected = sigSize + publicKeyBytes().toInt();
      if (bytes.length != expected) {
        throw Exception('Invalid signature length: expected $expected bytes, got ${bytes.length}');
      }

      final signature = bytes.sublist(0, sigSize);
      final publicKey = bytes.sublist(sigSize);

      final hash = await ref
          .read(transactionSubmissionServiceProvider)
          .submitExternallySignedTransfer(
            account: widget.account,
            targetAddress: widget.recipientAddress,
            amount: widget.amount,
            fee: widget.networkFee,
            blockHeight: widget.blockHeight,
            unsignedData: widget.unsignedData,
            signature: signature,
            publicKey: publicKey,
          );

      unawaited(
        RecentAddressesService()
            .addAddress(widget.recipientAddress)
            .catchError((Object e) => debugPrint('Failed to save recent address: $e')),
      );

      ref.read(keystoneSignCacheProvider.notifier).startNewSendSession();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SendTerminalScreen(content: widget.terminal.copyWith(explorerUrl: explorerImmediateTransactionUrl(hash))),
        ),
      );
    } catch (e, st) {
      quantusDebugPrint('Keystone signature processing failed: $e');
      TelemetryService().sendError('Keystone signature processing failed', error: e, stackTrace: st);
      ref.read(keystoneSignCacheProvider.notifier).reset();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _done = false;
        _error = ref.read(l10nProvider).keystoneScanError;
        _parts.clear();
        _seenSeq.clear();
        _expectedParts = null;
      });
      await _controller.start();
    }
  }

  Future<void> _simulateSignature() async {
    if (_done) return;
    _done = true;
    await _controller.stop();
    try {
      final keypair = await widget.account.getKeypair();
      final signed = signMessageWithPubkey(keypair: keypair, message: widget.unsignedData.encodedPayloadToSign);
      await _submit(encodeUr(data: signed));
    } catch (e, st) {
      quantusDebugPrint('Keystone signature simulation failed: $e');
      TelemetryService().sendError('Keystone signature simulation failed', error: e, stackTrace: st);
      ref.read(keystoneSignCacheProvider.notifier).reset();
      if (!mounted) return;
      setState(() {
        _done = false;
        _error = ref.read(l10nProvider).keystoneScanError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final colors = context.colors;
    final text = context.themeText;
    final size = MediaQuery.of(context).size;
    final frame = (size.width - 96).clamp(220.0, 300.0);
    final progress = _expectedParts == null ? null : (_seenSeq.length / _expectedParts!).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: frame,
              height: frame,
              decoration: BoxDecoration(
                border: Border.all(color: colors.accentOrange, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  QuantusIconButton.rounded(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                    style: IconButtonStyle.glass,
                  ),
                  const Spacer(),
                  QuantusIconButton.rounded(
                    icon: Icons.flash_on,
                    onTap: _controller.toggleTorch,
                    style: IconButtonStyle.glass,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error ?? l10n.keystoneScanInstruction,
                  style: text.paragraph?.copyWith(color: _error != null ? colors.error : Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (progress != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: colors.surface,
                      color: colors.accentOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.keystoneScanProgress(_seenSeq.length, _expectedParts!),
                    style: text.detail?.copyWith(color: Colors.white70),
                  ),
                ] else if (_parts.isNotEmpty)
                  Text(l10n.keystoneScanScanning(_parts.length), style: text.detail?.copyWith(color: Colors.white70)),
                if (AppConstants.debugHardwareWallet && !_submitting) ...[
                  const SizedBox(height: 16),
                  QuantusButton.simple(
                    label: 'DEBUG: Simulate signature',
                    onTap: _simulateSignature,
                    variant: ButtonVariant.danger,
                    width: null,
                  ),
                ],
              ],
            ),
          ),
          if (_submitting) _buildSubmittingOverlay(colors, text, l10n),
        ],
      ),
    );
  }

  Widget _buildSubmittingOverlay(AppColorsV2 colors, AppTextTheme text, AppLocalizations l10n) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.useOpacity(0.7),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.accentOrange),
              const SizedBox(height: 16),
              Text(l10n.keystoneScanSubmitting, style: text.paragraph?.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
