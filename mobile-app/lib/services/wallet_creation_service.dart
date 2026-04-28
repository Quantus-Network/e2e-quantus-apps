import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/services/referral_service.dart';

/// Persistence and side effects used when finalizing a newly generated wallet.
/// Production uses [SdkWalletCreationDependencies]; tests supply a fake.
abstract class WalletCreationDependencies {
  Future<void> setMnemonic(String mnemonic, int walletIndex);

  Future<void> addAccount(Account account);

  Future<void> submitReferralForNewWallet();
}

class SdkWalletCreationDependencies implements WalletCreationDependencies {
  final SettingsService _settings = SettingsService();
  final AccountsService _accounts = AccountsService();
  final ReferralService _referral = ReferralService();

  @override
  Future<void> setMnemonic(String mnemonic, int walletIndex) {
    return _settings.setMnemonic(mnemonic, walletIndex);
  }

  @override
  Future<void> addAccount(Account account) {
    return _accounts.addAccount(account);
  }

  @override
  Future<void> submitReferralForNewWallet() async {
    try {
      await _referral.submitAddressToBackend();
    } catch (_) {}
  }
}

class WalletCreationService {
  WalletCreationService({WalletCreationDependencies? dependencies})
    : _dependencies = dependencies ?? SdkWalletCreationDependencies();

  final WalletCreationDependencies _dependencies;

  /// Saves [mnemonic] for [walletIndex], adds the root account when missing,
  /// and runs referral registration for brand-new roots.
  ///
  /// Returns the root [Account] row to use after persistence (newly created or
  /// already present).
  Future<Account> createNewWallet({
    required String name,
    required String mnemonic,
    required int walletIndex,
    required String accountId,
    required List<Account> existingAccounts,
  }) async {
    await _dependencies.setMnemonic(mnemonic, walletIndex);

    final hasRoot = existingAccounts.any((a) => a.walletIndex == walletIndex && a.index == 0);
    if (!hasRoot) {
      final account = Account(walletIndex: walletIndex, index: 0, name: name, accountId: accountId);
      await _dependencies.addAccount(account);
      await _dependencies.submitReferralForNewWallet();
      return account;
    }

    return existingAccounts.firstWhere((a) => a.walletIndex == walletIndex && a.index == 0);
  }
}
