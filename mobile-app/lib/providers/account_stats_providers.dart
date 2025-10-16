import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/services/referral_service.dart';

class AccountStatsNotifier extends StateNotifier<AsyncValue<AccountStats>> {
  final TaskmasterService _taskmasterService = TaskmasterService();
  final ReferralService _referralService = ReferralService();

  AccountStatsNotifier() : super(const AsyncValue.loading()) {
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final account = await _referralService.getMainAccount();
      final accountStats = await _taskmasterService.getAccountStats(account);
      state = AsyncValue.data(accountStats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void reset() {
    state = const AsyncValue.loading();
  }
}

final accountsStatsProvider =
    StateNotifierProvider<AccountStatsNotifier, AsyncValue<AccountStats>>((
      ref,
    ) {
      return AccountStatsNotifier();
    });
