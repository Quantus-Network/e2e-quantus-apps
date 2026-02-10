import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/shared/extensions/transaction_event_extension.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

void showTransactionDetailSheet(BuildContext context, TransactionEvent tx, String activeAccountId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TransactionDetailSheet(tx: tx, activeAccountId: activeAccountId),
  );
}

class _TransactionDetailSheet extends StatefulWidget {
  final TransactionEvent tx;
  final String activeAccountId;
  const _TransactionDetailSheet({required this.tx, required this.activeAccountId});

  @override
  State<_TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<_TransactionDetailSheet> {
  final _checksumService = HumanReadableChecksumService();
  String? _checkphrase;

  bool get _isSend => widget.tx.from == widget.activeAccountId;
  String get _counterparty => _isSend ? widget.tx.to : widget.tx.from;

  @override
  void initState() {
    super.initState();
    _checksumService.getHumanReadableName(_counterparty).then((name) {
      if (mounted) setState(() => _checkphrase = name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.themeText;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: const Color(0xFF3D3D3D)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerRow(colors, text),
                const SizedBox(height: 72),
                _amountCard(colors, text),
                const SizedBox(height: 56),
                _addressSection(colors, text),
                const SizedBox(height: 56),
                _feeRow(colors, text),
                const SizedBox(height: 32),
                _explorerButton(colors, text),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerRow(AppColorsV2 colors, AppTextTheme text) {
    final label = widget.tx.isReversibleScheduled
        ? (_isSend ? 'Pending' : 'Receiving')
        : _isSend
            ? 'Sent'
            : 'Received';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 20)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close, color: colors.textPrimary, size: 20),
        ),
      ],
    );
  }

  Widget _amountCard(AppColorsV2 colors, AppTextTheme text) {
    final fmt = NumberFormattingService();
    final amount = fmt.formatBalance(widget.tx.amount);
    final date = DateFormat('MMM d, yyyy').format(widget.tx.timestamp);
    final time = DateFormat('h:mm a').format(widget.tx.timestamp);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$amount ${AppConstants.tokenSymbol}',
                  style: text.smallTitle?.copyWith(color: colors.textPrimary, fontSize: 32, fontWeight: FontWeight.w600)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: text.smallParagraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('At $time', style: text.detail?.copyWith(color: Colors.white.withValues(alpha: 0.5))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addressSection(AppColorsV2 colors, AppTextTheme text) {
    final direction = _isSend ? 'To:' : 'From:';
    final address = AddressFormattingService.formatAddress(_counterparty, prefix: 15, ellipses: '.......', postFix: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(direction, style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(address,
                  style: text.smallParagraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            _copyButton(colors, _counterparty),
          ],
        ),
        if (_checkphrase != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(_checkphrase!, style: text.smallParagraph?.copyWith(color: const Color(0xFFED4CCE))),
              ),
              const SizedBox(width: 8),
              _copyButton(colors, _checkphrase!),
            ],
          ),
        ],
      ],
    );
  }

  Widget _copyButton(AppColorsV2 colors, String value) {
    return GestureDetector(
      onTap: () => Clipboard.setData(ClipboardData(text: value)),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.copy, size: 12, color: Colors.white),
      ),
    );
  }

  Widget _feeRow(AppColorsV2 colors, AppTextTheme text) {
    BigInt? fee;
    if (widget.tx is TransferEvent) {
      fee = (widget.tx as TransferEvent).fee;
    } else if (widget.tx is PendingTransactionEvent) {
      fee = (widget.tx as PendingTransactionEvent).fee;
    }
    final fmt = NumberFormattingService();
    final feeStr = fee != null ? '${fmt.formatBalance(fee)} ${AppConstants.tokenSymbol}' : '--';
    final style = text.detail?.copyWith(color: Colors.white.withValues(alpha: 0.5));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Network Fee:', style: style),
        Text(feeStr, style: style),
      ],
    );
  }

  Widget _explorerButton(AppColorsV2 colors, AppTextTheme text) {
    return GestureDetector(
      onTap: _openExplorer,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.44)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('View in Explorer', style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new, size: 16, color: colors.textPrimary),
          ],
        ),
      ),
    );
  }

  void _openExplorer() {
    final tx = widget.tx;
    final isMinerReward = tx.isMinerReward;
    final transactionType = isMinerReward
        ? 'miner-rewards'
        : (tx.isReversibleScheduled || tx.isReversibleExecuted || tx.isReversibleCancelled)
            ? 'reversible-transactions'
            : 'immediate-transactions';

    String? path;
    if (tx.extrinsicHash != null) {
      path = '$transactionType/${tx.extrinsicHash}';
    } else if (isMinerReward && tx.blockHash != null) {
      path = '$transactionType/${tx.blockHash}';
    }
    if (path != null) {
      launchUrl(Uri.parse('${AppConstants.explorerEndpoint}/$path'));
    }
  }
}
