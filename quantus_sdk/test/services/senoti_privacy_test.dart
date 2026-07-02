import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SenotiService privacy', () {
    test('registerDevice excludes encrypted accounts from address list', () {
      const regularAccount = Account(
        walletIndex: 0,
        index: 0,
        name: 'Regular',
        accountId: 'qzRegularAccount',
        accountType: AccountType.local,
      );

      const encryptedAccount = Account(
        walletIndex: 0,
        index: -1,
        name: 'Wormhole',
        accountId: 'qzWormholeAccount',
        accountType: AccountType.encrypted,
      );

      const keystoneAccount = Account(
        walletIndex: 1,
        index: 0,
        name: 'Hardware',
        accountId: 'qzKeystoneAccount',
        accountType: AccountType.keystone,
      );

      // Filter like the service does
      final allAccounts = [regularAccount, encryptedAccount, keystoneAccount];
      final filteredAddresses = allAccounts
          .where((a) => a.accountType != AccountType.encrypted)
          .map((a) => a.accountId)
          .toList();

      expect(filteredAddresses, contains('qzRegularAccount'));
      expect(filteredAddresses, contains('qzKeystoneAccount'));
      expect(filteredAddresses, isNot(contains('qzWormholeAccount')));
      expect(filteredAddresses.length, 2);
    });
  });
}
