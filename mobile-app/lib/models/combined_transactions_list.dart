import 'package:quantus_sdk/quantus_sdk.dart';

class CombinedTransactionsList {
  final Set<String> pendingCancellationIds;
  final List<PendingTransactionEvent> pendingTransactions;
  final List<ReversibleTransferEvent> reversibleTransfers;
  final List<TransactionEvent> otherTransfers;

  CombinedTransactionsList({
    required this.pendingCancellationIds,
    required this.pendingTransactions,
    required this.reversibleTransfers,
    required this.otherTransfers,
  });

  CombinedTransactionsList copyWith({
    Set<String>? pendingCancellationIds,
    List<PendingTransactionEvent>? pendingTransactions,
    List<ReversibleTransferEvent>? reversibleTransfers,
    List<TransactionEvent>? otherTransfers,
  }) {
    return CombinedTransactionsList(
      pendingCancellationIds: pendingCancellationIds ?? this.pendingCancellationIds,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      reversibleTransfers: reversibleTransfers ?? this.reversibleTransfers,
      otherTransfers: otherTransfers ?? this.otherTransfers,
    );
  }

  static CombinedTransactionsList get empty => CombinedTransactionsList(
    pendingCancellationIds: <String>{},
    pendingTransactions: [],
    reversibleTransfers: [],
    otherTransfers: [],
  );
}
