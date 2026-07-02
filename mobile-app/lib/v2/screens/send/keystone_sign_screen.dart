import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/providers/currency_display_provider.dart';
import 'package:resonance_network_wallet/providers/l10n_provider.dart';
import 'package:resonance_network_wallet/providers/wallet_providers.dart';
import 'package:resonance_network_wallet/services/telemetry_service.dart';
import 'package:resonance_network_wallet/shared/utils/print.dart';
import 'package:resonance_network_wallet/v2/components/animated_ur_qr.dart';
import 'package:resonance_network_wallet/v2/components/loader.dart';
import 'package:resonance_network_wallet/v2/components/quantus_button.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base.dart';
import 'package:resonance_network_wallet/v2/components/scaffold_base_bottom_content.dart';
import 'package:resonance_network_wallet/v2/components/v2_app_bar.dart';
import 'package:resonance_network_wallet/v2/screens/send/keystone_scan_signature_screen.dart';
import 'package:resonance_network_wallet/v2/screens/send/send_strategy.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

/// Builds the unsigned transaction payload for a Keystone (hardware) account and
/// renders it as an (animated) UR QR code for the device to scan. The user then
/// proceeds to scan the signature back from the device.
class KeystoneSignScreen extends ConsumerStatefulWidget {
  final Account account;
  final String recipientAddress;
  final BigInt amount;
  final BigInt networkFee;
  final int blockHeight;
  final String recipientChecksum;
  final bool isPayMode;
  final SendTerminalContent terminal;

  const KeystoneSignScreen({
    super.key,
    required this.account,
    required this.recipientAddress,
    required this.amount,
    required this.networkFee,
    required this.blockHeight,
    required this.recipientChecksum,
    required this.terminal,
    this.isPayMode = false,
  });

  @override
  ConsumerState<KeystoneSignScreen> createState() => _KeystoneSignScreenState();
}

class _KeystoneSignScreenState extends ConsumerState<KeystoneSignScreen> {
  UnsignedTransactionData? _unsignedData;
  List<String>? _urParts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final substrate = ref.read(substrateServiceProvider);
      final call = ref.read(balancesServiceProvider).getBalanceTransferCall(widget.recipientAddress, widget.amount);
      final unsigned = await substrate.getUnsignedTransactionPayload(widget.account, call);
      final parts = encodeUr(data: unsigned.encodedPayloadRaw);
      if (parts.isEmpty) throw Exception('Failed to encode transaction payload as UR');
      if (!mounted) return;
      setState(() {
        _unsignedData = unsigned;
        _urParts = parts;
      });
    } catch (e, st) {
      quantusDebugPrint('Keystone payload preparation failed: $e');
      TelemetryService().sendError('Keystone payload preparation failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _error = ref.read(l10nProvider).keystoneSignError);
    }
  }

  void _goToScan() {
    final unsignedData = _unsignedData;
    if (unsignedData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KeystoneScanSignatureScreen(
          account: widget.account,
          unsignedData: unsignedData,
          recipientAddress: widget.recipientAddress,
          amount: widget.amount,
          networkFee: widget.networkFee,
          blockHeight: widget.blockHeight,
          recipientChecksum: widget.recipientChecksum,
          isPayMode: widget.isPayMode,
          terminal: widget.terminal,
        ),
      ),
    );
  }

  Widget _transactionDetails(AppColorsV2 colors, AppTextTheme text, CurrencyDisplayState amountDisplay) {
    return Column(
      children: [
        Text(
          '${amountDisplay.primaryAmount} ${AppConstants.tokenSymbol}',
          style: text.smallTitle?.copyWith(color: colors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.recipientAddress.trim(),
          style: text.detail?.copyWith(
            color: colors.textMuted,
            fontFamily: AppTextTheme.fontFamilySecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          widget.recipientChecksum,
          style: text.smallParagraph?.copyWith(color: colors.checksum, height: 1.2),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final colors = context.colors;
    final text = context.themeText;
    final amountDisplay = ref.watch(txAmountDisplayProvider)(
      widget.amount,
      isSend: true,
      withSignPrefix: false,
      withQuanSymbol: false,
      quanDecimals: 4,
    );

    return ScaffoldBase(
      appBar: V2AppBar(title: widget.isPayMode ? l10n.sendPayTitle : l10n.sendTitle),
      mainContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(l10n.keystoneSignTitle, style: text.smallTitle, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            l10n.keystoneSignInstruction,
            style: text.smallParagraph?.copyWith(color: colors.textTertiary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _transactionDetails(colors, text, amountDisplay),
          const SizedBox(height: 24),
          Expanded(child: Center(child: _buildQr(colors, text))),
        ],
      ),
      bottomContent: ScaffoldBaseBottomContent(
        child: QuantusButton.simple(
          label: l10n.keystoneSignNext,
          variant: ButtonVariant.primary,
          isDisabled: _unsignedData == null,
          onTap: _goToScan,
        ),
      ),
    );
  }

  Widget _buildQr(AppColorsV2 colors, AppTextTheme text) {
    final error = _error;
    if (error != null) {
      return Text(
        error,
        style: text.detail?.copyWith(color: colors.textError),
        textAlign: TextAlign.center,
      );
    }
    final parts = _urParts;
    if (parts == null) return const Loader();
    return AnimatedUrQr(parts: parts);
  }
}
