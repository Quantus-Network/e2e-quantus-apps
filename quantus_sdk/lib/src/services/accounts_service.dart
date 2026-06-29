import 'package:quantus_sdk/quantus_sdk.dart';

// We define the following 5 levels in BIP32 path:
// m / purpose' / coin_type' / account' / change / address_index
// For Quantus purpose should be 189 or if that's not available maybe 1899
// coin type should be 0 for native
// account is the account index - 1, 2, 3...
// change and address index should remain at 0

// Bip44 describes account discovery from seed phrase - it keeps looking by increasing acocunt index, for accounts with activity.
// It defines the max allowed account gap as 20, if there's 20 addresses in a row where there's no activity, it assumes the highest index has been reached.

class AccountsService {
  static final AccountsService _instance = AccountsService._internal();
  factory AccountsService() => _instance;
  AccountsService._internal();

  final SettingsService _settingsService = SettingsService();
  void Function()? onAccountsChanged;

  /// Creates a new account draft with the next available index.
  ///
  /// Note: This does NOT persist the account. Call [addAccount] after any
  /// modifications (e.g., setting a custom name) to save the account.
  ///
  /// If concurrent callers create accounts before either persists, the second
  /// [addAccount] call will fail with a duplicate error. Consider using
  /// [createAndAddAccount] for atomic creation when no modifications are needed.
  Future<Account> createNewAccount({required int walletIndex}) async {
    final mnemonic = await _settingsService.getMnemonic(walletIndex);
    if (mnemonic == null) {
      throw Exception('Mnemonic not found. Cannot create new account.');
    }
    final nextIndex = await _settingsService.getNextFreeAccountIndex(walletIndex);
    final keypair = HdWalletService().keyPairAtIndex(mnemonic, nextIndex);
    final newAccount = Account(
      walletIndex: walletIndex,
      index: nextIndex,
      name: 'Account ${nextIndex + 1}',
      accountId: keypair.ss58Address,
    );
    return newAccount;
  }

  /// Atomically creates and persists a new account in a single operation.
  ///
  /// Use this when you don't need to modify the account before persisting.
  /// The [name] parameter allows setting a custom account name.
  Future<Account> createAndAddAccount({required int walletIndex, String? name}) async {
    final mnemonic = await _settingsService.getMnemonic(walletIndex);
    if (mnemonic == null) {
      throw Exception('Mnemonic not found. Cannot create new account.');
    }

    final account = await _settingsService.createAndAddAccount(
      walletIndex: walletIndex,
      buildAccount: (nextIndex) async {
        final keypair = HdWalletService().keyPairAtIndex(mnemonic, nextIndex);
        return Account(
          walletIndex: walletIndex,
          index: nextIndex,
          name: name ?? 'Account ${nextIndex + 1}',
          accountId: keypair.ss58Address,
        );
      },
    );

    onAccountsChanged?.call();
    return account;
  }

  Future<Account> createEncryptedAccount({required int walletIndex, required String name}) async {
    final mnemonic = await _settingsService.getMnemonic(walletIndex);
    if (mnemonic == null) {
      throw Exception('Mnemonic not found. Cannot create encrypted account.');
    }
    final keyPair = HdWalletService().deriveWormholeKeyPair(mnemonic: mnemonic);
    return Account(
      walletIndex: walletIndex,
      index: AppConstants.encryptedAccountIndex,
      name: name,
      accountId: keyPair.address,
      accountType: AccountType.encrypted,
    );
  }

  /// Ensures every software (non-hardware) wallet has its single encrypted
  /// (wormhole) account persisted. Idempotent; returns true if any were added.
  Future<bool> ensureEncryptedAccountsForSoftwareWallets({required String name}) async {
    final accounts = await getAccounts();
    final byWallet = <int, List<Account>>{};
    for (final a in accounts) {
      byWallet.putIfAbsent(a.walletIndex, () => []).add(a);
    }

    var created = false;
    for (final entry in byWallet.entries) {
      final group = entry.value;
      final isHardware = group.every((a) => a.accountType == AccountType.keystone);
      final hasEncrypted = group.any((a) => a.accountType == AccountType.encrypted);
      if (isHardware || hasEncrypted) continue;
      final account = await createEncryptedAccount(walletIndex: entry.key, name: name);
      await addAccount(account);
      created = true;
    }
    return created;
  }

  Future<void> updateAccountName(Account account, String name) async {
    if (name.isEmpty) {
      throw Exception("Account name can't be empty");
    }
    final updatedAccount = account.copyWith(name: name);
    await _settingsService.updateAccount(updatedAccount);
    onAccountsChanged?.call();
  }

  Future<void> addAccount(Account newAccount) async {
    await _settingsService.addAccount(newAccount);
    onAccountsChanged?.call();
  }

  Future<List<Account>> getAccounts() async {
    return await _settingsService.getAccounts();
  }

  Future<void> removeAccount(Account account) async {
    await _settingsService.removeAccount(account);
    onAccountsChanged?.call();
  }

  /// Removes an entire wallet (all its accounts plus its stored mnemonic). The
  /// primary wallet (index 0) cannot be removed.
  Future<void> removeWallet(int walletIndex) async {
    await _settingsService.removeWallet(walletIndex);
    onAccountsChanged?.call();
  }
}
