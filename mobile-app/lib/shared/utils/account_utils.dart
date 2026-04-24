import 'package:quantus_sdk/quantus_sdk.dart';

List<int> getNonHardwareWalletIndices(List<Account> accounts) {
  final nonHardwareWalletIndices = <int>{};
  for (final account in accounts) {
    if (account.accountType != AccountType.keystone) {
      nonHardwareWalletIndices.add(account.walletIndex);
    }
  }
  return nonHardwareWalletIndices.toList()..sort();
}

/// Smallest non-negative index not used as [Account.walletIndex] by any non-hardware account.
/// Use when importing a new recovery phrase or otherwise adding a distinct software HD wallet.
int nextNonHardwareWalletIndex(List<Account> accounts) {
  final used = getNonHardwareWalletIndices(accounts).toSet();
  var i = 0;
  while (used.contains(i)) {
    i++;
  }
  return i;
}
