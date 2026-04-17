import 'package:quantus_sdk/quantus_sdk.dart';

/// Immutable key used to parameterise the filtered-transactions provider family.
///
/// Riverpod family keys must implement [==] and [hashCode]; this class
/// satisfies that requirement so every unique (accountIds, filter) combination
/// gets its own isolated [StateNotifier].
class FilteredTransactionsParams {
  final List<String> accountIds;
  final TransactionFilter filter;

  const FilteredTransactionsParams({required this.accountIds, required this.filter});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilteredTransactionsParams &&
          _listEquals(other.accountIds, accountIds) &&
          other.filter == filter;

  @override
  int get hashCode => Object.hash(Object.hashAll(accountIds), filter);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
