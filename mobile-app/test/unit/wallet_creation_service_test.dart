import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/services/wallet_creation_service.dart';

class _FakeDeps implements WalletCreationDependencies {
  String? lastMnemonic;
  int? lastWalletIndex;
  final List<Account> addedAccounts = [];
  int referralCalls = 0;

  @override
  Future<void> addAccount(Account account) async {
    addedAccounts.add(account);
  }

  @override
  Future<void> setMnemonic(String mnemonic, int walletIndex) async {
    lastMnemonic = mnemonic;
    lastWalletIndex = walletIndex;
  }

  @override
  Future<void> submitReferralForNewWallet() async {
    referralCalls++;
  }
}

void main() {
  group('WalletCreationService.createNewWallet', () {
    test('persists mnemonic, adds root account, and submits referral when no root exists', () async {
      final deps = _FakeDeps();
      final service = WalletCreationService(dependencies: deps);

      const mnemonic = 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
      const accountId = 'abc';
      const name = 'Account 1';

      final created = await service.createNewWallet(
        name: name,
        mnemonic: mnemonic,
        walletIndex: 0,
        accountId: accountId,
        existingAccounts: const [],
      );

      expect(deps.lastMnemonic, mnemonic);
      expect(deps.lastWalletIndex, 0);
      expect(deps.addedAccounts, hasLength(1));
      expect(deps.addedAccounts.single.accountId, accountId);
      expect(deps.addedAccounts.single.name, name);
      expect(deps.addedAccounts.single.walletIndex, 0);
      expect(deps.addedAccounts.single.index, 0);
      expect(deps.referralCalls, 1);

      expect(created.accountId, accountId);
      expect(created.name, name);
    });

    test('skips add and referral when root account already exists', () async {
      final deps = _FakeDeps();
      final service = WalletCreationService(dependencies: deps);

      const existing = Account(walletIndex: 0, index: 0, name: 'Existing', accountId: 'existing_addr');

      final created = await service.createNewWallet(
        name: 'Account 1',
        mnemonic: 'word ' * 12,
        walletIndex: 0,
        accountId: 'new_derived_addr',
        existingAccounts: const [existing],
      );

      expect(deps.lastMnemonic, isNotNull);
      expect(deps.addedAccounts, isEmpty);
      expect(deps.referralCalls, 0);
      expect(created, same(existing));
    });
  });
}
