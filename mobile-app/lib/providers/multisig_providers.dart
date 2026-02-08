import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

final multisigServiceProvider = Provider<MultisigService>((ref) {
  return MultisigService();
});

final multisigAccountsProvider = FutureProvider<List<MultisigAccount>>((ref) async {
  final service = ref.watch(multisigServiceProvider);
  return await service.getSavedMultisigAccounts();
});

final activeMultisigDataProvider = FutureProvider.family<MultisigData?, String>((ref, address) async {
  final service = ref.watch(multisigServiceProvider);
  return await service.getMultisigData(address);
});

final multisigProposalsProvider =
    FutureProvider.family<List<(int, ProposalData)>, String>((ref, multisigAddress) async {
  final service = ref.watch(multisigServiceProvider);
  return await service.getActiveProposals(multisigAddress);
});

final currentBlockNumberProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(multisigServiceProvider);
  return await service.getCurrentBlockNumber();
});
