import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/models/combined_transactions_list.dart';
import 'package:resonance_network_wallet/models/filtered_transactions_params.dart';
import 'package:resonance_network_wallet/providers/account_id_list_cache.dart';
import 'package:resonance_network_wallet/providers/account_providers.dart';
import 'package:resonance_network_wallet/providers/filtered_all_transactions_provider.dart';

/// Provides a filtered list of transactions for the currently active account.
///
/// Parameterised by [TransactionFilter] so callers can independently watch
/// the send-only, receive-only, or combined history.
final activeAccountTransactionsProvider =
    Provider.family<AsyncValue<CombinedTransactionsList>, TransactionFilter>((ref, filter) {
  final activeAccountValue = ref.watch(activeAccountProvider);

  return activeAccountValue.when(
    data: (activeAccount) {
      if (activeAccount == null) {
        return AsyncValue.data(CombinedTransactionsList.empty);
      }
      final params = FilteredTransactionsParams(
        accountIds: AccountIdListCache.get([activeAccount.account.accountId]),
        filter: filter,
      );
      return ref.watch(filteredTransactionsProviderFamily(params));
    },
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
