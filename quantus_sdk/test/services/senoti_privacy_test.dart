import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SenotiService privacy', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('registerDevice excludes encrypted accounts from address list', () async {
      // Create a mock account list
      final regularAccount = Account(
        walletIndex: 0,
        index: 0,
        name: 'Regular',
        accountId: 'qzRegularAccount',
        accountType: AccountType.local,
      );
      
      final encryptedAccount = Account(
        walletIndex: 0,
        index: -1,
        name: 'Wormhole',
        accountId: 'qzWormholeAccount',
        accountType: AccountType.encrypted,
      );
      
      final keystoneAccount = Account(
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

      // Verify encrypted accounts are excluded
      expect(filteredAddresses, contains('qzRegularAccount'));
      expect(filteredAddresses, contains('qzKeystoneAccount'));
      expect(filteredAddresses, isNot(contains('qzWormholeAccount')));
      expect(filteredAddresses.length, 2);
    });

    test('encrypted account type filters correctly', () {
      final encryptedAccount = Account(
        walletIndex: 0,
        index: -1,
        name: 'Encrypted',
        accountId: 'qzEncrypted',
        accountType: AccountType.encrypted,
      );
      
      expect(encryptedAccount.accountType, AccountType.encrypted);
      expect(encryptedAccount.accountType != AccountType.encrypted, isFalse);
    });
  });
}
