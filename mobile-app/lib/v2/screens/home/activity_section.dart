import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/features/components/skeleton.dart';
import 'package:resonance_network_wallet/features/main/screens/transactions_screen.dart';
import 'package:resonance_network_wallet/models/combined_transactions_list.dart';
import 'package:resonance_network_wallet/services/transaction_service.dart';
import 'package:resonance_network_wallet/shared/extensions/transaction_event_extension.dart';
import 'package:resonance_network_wallet/v2/theme/app_colors.dart';
import 'package:resonance_network_wallet/v2/theme/app_text_styles.dart';

class ActivitySection extends ConsumerWidget {
  final AsyncValue<CombinedTransactionsList> txAsync;
  final BaseAccount activeAccount;
  final Future<void> Function()? onRetry;

  const ActivitySection({super.key, required this.txAsync, required this.activeAccount, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = context.themeText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: txAsync.when(
        data: (data) {
          final txService = ref.read(transactionServiceProvider);
          final all = txService.combineAndDeduplicateTransactions(
            pendingCancellationIds: data.pendingCancellationIds,
            pendingTransactions: data.pendingTransactions,
            reversibleTransfers: data.reversibleTransfers,
            otherTransfers: data.otherTransfers,
          );

          if (all.isEmpty) return const SizedBox.shrink();

          return Column(
            children: [
              const SizedBox(height: 40),
              _header(colors, text, context),
              const SizedBox(height: 24),
              ...all.take(5).map((tx) => _txItem(tx, colors, text)),
            ],
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(colors, text, context),
              const SizedBox(height: 24),
              for (var i = 0; i < 3; i++) ...[
                const Skeleton(width: double.infinity, height: 32),
                if (i < 2) Divider(color: colors.separator, height: 24),
              ],
            ],
          ),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Column(
            children: [
              Text('Error loading transactions', style: text.detail?.copyWith(color: colors.textError)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => onRetry?.call(),
                child: Text('Retry', style: text.smallParagraph?.copyWith(color: colors.textPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppColorsV2 colors, AppTextTheme text, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Activity', style: text.paragraph?.copyWith(color: colors.textPrimary, fontWeight: FontWeight.w500)),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionsScreen(fixedAccountId: activeAccount.accountId, showAccountFilter: false),
            ),
          ),
          child: Text(
            'View All',
            style: text.paragraph?.copyWith(color: colors.textSecondary, decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _txItem(TransactionEvent tx, AppColorsV2 colors, AppTextTheme text) {
    final accountId = activeAccount.accountId;
    final isSend = tx.from == accountId;
    final isScheduled = tx.isReversibleScheduled;

    final label = isScheduled
        ? (isSend ? 'Pending' : 'Receiving')
        : isSend
            ? 'Sent'
            : 'Received';

    final timeLabel = isScheduled ? _formatDuration(tx.timeRemaining) : _timeAgo(tx.timestamp);

    final iconBg = isScheduled && !isSend
        ? const Color(0x2927F027)
        : isScheduled && isSend
            ? const Color(0x29FFBC42)
            : colors.surface;
    final iconColor = isScheduled && !isSend
        ? const Color(0xFF27F027)
        : isScheduled && isSend
            ? const Color(0xFFFFBC42)
            : colors.textSecondary;

    final fmt = NumberFormattingService();
    final amount = fmt.formatBalance(tx.amount);
    final addr = _shortenAddress(isSend ? tx.to : tx.from);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
                child: Transform.rotate(
                  angle: isSend ? 3.14159 : 0,
                  child: Icon(Icons.arrow_downward_rounded, size: 16, color: iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.smallParagraph?.copyWith(color: colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(timeLabel, style: text.detail?.copyWith(color: colors.textTertiary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$amount ${AppConstants.tokenSymbol}', style: text.smallParagraph?.copyWith(color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('${isSend ? "To" : "From"}: $addr', style: text.detail?.copyWith(color: colors.textTertiary)),
                ],
              ),
            ],
          ),
        ),
        Divider(color: colors.separator, height: 1),
      ],
    );
  }

  String _shortenAddress(String addr) {
    if (addr.length <= 10) return addr;
    return '${addr.substring(0, 5)}...${addr.substring(addr.length - 3)}';
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    return '${days.toString().padLeft(2, '0')}d:${hours.toString().padLeft(2, '0')}h:${mins.toString().padLeft(2, '0')}m';
  }

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
