import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/models/transaction_role.dart';

/// Utility functions for handling transactions
class TransactionUtils {
  /// Combines and deduplicates transactions from multiple sources
  /// Priority order: pending -> reversible -> other
  /// Duplicates are removed based on transaction ID
  static List<TransactionEvent> combineAndDeduplicateTransactions({
    required Set<String> pendingCancellationIds,
    required List<PendingTransactionEvent> pendingTransactions,
    required List<ReversibleTransferEvent> reversibleTransfers,
    required List<TransactionEvent> otherTransfers,
  }) {
    final seenIds = <String>{};
    final List<TransactionEvent> result = [];

    // Add pending transactions first (highest priority)
    for (final transaction in pendingTransactions) {
      if (seenIds.add(transaction.id)) {
        if (transaction.isReversible && pendingCancellationIds.contains(transaction.id)) {
          result.add(transaction.copyWith(status: ReversibleTransferStatus.CANCELLED));
        } else {
          result.add(transaction);
        }
      }
    }

    // Add reversible transfers (medium priority)
    for (final transaction in reversibleTransfers) {
      if (transaction.status == ReversibleTransferStatus.SCHEDULED) {
        if (seenIds.add(transaction.id)) {
          if (pendingCancellationIds.contains(transaction.id)) {
            result.add(transaction.copyWith(status: ReversibleTransferStatus.CANCELLED));
          } else {
            result.add(transaction);
          }
        }
      }
    }

    // Add other transfers (lowest priority)
    for (final transaction in otherTransfers) {
      if (seenIds.add(transaction.id)) {
        result.add(transaction);
      }
    }

    return result;
  }

  static TransactionRole getTransactionRole(TransactionEvent transaction, List<String> accountIds) {
    final isFrom = accountIds.contains(transaction.from);
    final isTo = accountIds.contains(transaction.to);

    if (isFrom && isTo) {
      return TransactionRole.both;
    } else if (isFrom) {
      return TransactionRole.sender;
    } else {
      return TransactionRole.receiver;
    }
  }
}
