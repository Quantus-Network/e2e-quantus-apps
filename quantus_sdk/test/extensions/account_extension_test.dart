@Tags(['native'])
library;

import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mnemonic =
      'orchard answer curve patient visual flower maze noise retreat penalty cage small earth domain scan pitch bottom crunch theme club client swap slice raven';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    await QuantusSdk.init();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    await SettingsService().initialize();
    await SettingsService().setMnemonic(mnemonic, 0);
  });

  group('Account.getKeypair() type-aware derivation', () {
    test('local account returns correctly derived keypair', () async {
      final hdService = HdWalletService();
      final expectedKeypair = hdService.keyPairAtIndex(mnemonic, 0);

      final account = Account(
        walletIndex: 0,
        index: 0,
        name: 'Test Account',
        accountId: expectedKeypair.ss58Address,
        accountType: AccountType.local,
      );

      final derivedKeypair = await account.getKeypair();

      expect(derivedKeypair.ss58Address, equals(expectedKeypair.ss58Address));
      expect(derivedKeypair.publicKey, equals(expectedKeypair.publicKey));
    });

    test('local account at higher index returns correctly derived keypair', () async {
      final hdService = HdWalletService();
      final expectedKeypair = hdService.keyPairAtIndex(mnemonic, 5);

      final account = Account(
        walletIndex: 0,
        index: 5,
        name: 'Test Account 5',
        accountId: expectedKeypair.ss58Address,
        accountType: AccountType.local,
      );

      final derivedKeypair = await account.getKeypair();

      expect(derivedKeypair.ss58Address, equals(expectedKeypair.ss58Address));
    });

    test('keystone account throws UnsupportedAccountTypeForSigningException', () async {
      final account = Account(
        walletIndex: 0,
        index: 0,
        name: 'Keystone Account',
        accountId: 'qzmSomeKeystoneAddress',
        accountType: AccountType.keystone,
      );

      expect(
        () => account.getKeypair(),
        throwsA(
          isA<UnsupportedAccountTypeForSigningException>().having(
            (e) => e.accountType,
            'accountType',
            AccountType.keystone,
          ),
        ),
      );
    });

    test('external account throws UnsupportedAccountTypeForSigningException', () async {
      final account = Account(
        walletIndex: 0,
        index: 0,
        name: 'External Account',
        accountId: 'qzmSomeExternalAddress',
        accountType: AccountType.external,
      );

      expect(
        () => account.getKeypair(),
        throwsA(
          isA<UnsupportedAccountTypeForSigningException>().having(
            (e) => e.accountType,
            'accountType',
            AccountType.external,
          ),
        ),
      );
    });

    test('encrypted account throws UnsupportedAccountTypeForSigningException', () async {
      // Encrypted accounts use wormhole derivation and can't sign regular extrinsics
      final hdService = HdWalletService();
      final wormholeKeyPair = hdService.deriveWormholeKeyPair(mnemonic: mnemonic);

      final account = Account(
        walletIndex: 0,
        index: AppConstants.encryptedAccountIndex,
        name: 'Encrypted Account',
        accountId: wormholeKeyPair.address,
        accountType: AccountType.encrypted,
      );

      expect(
        () => account.getKeypair(),
        throwsA(
          isA<UnsupportedAccountTypeForSigningException>().having(
            (e) => e.accountType,
            'accountType',
            AccountType.encrypted,
          ),
        ),
      );
    });
  });

  group('Account.getKeypair() address validation', () {
    test('mismatched accountId throws AccountAddressMismatchException', () async {
      final hdService = HdWalletService();
      final keypairIndex0 = hdService.keyPairAtIndex(mnemonic, 0);
      final keypairIndex1 = hdService.keyPairAtIndex(mnemonic, 1);

      // Account claims to have index 0 address but stores index 1 address
      final tamperedAccount = Account(
        walletIndex: 0,
        index: 0, // will derive keypair at index 0
        name: 'Tampered Account',
        accountId: keypairIndex1.ss58Address, // but claims to be index 1's address
        accountType: AccountType.local,
      );

      expect(
        () => tamperedAccount.getKeypair(),
        throwsA(
          isA<AccountAddressMismatchException>()
              .having((e) => e.expectedAddress, 'expectedAddress', keypairIndex1.ss58Address)
              .having((e) => e.derivedAddress, 'derivedAddress', keypairIndex0.ss58Address),
        ),
      );
    });

    test('correct accountId passes validation', () async {
      final hdService = HdWalletService();
      final expectedKeypair = hdService.keyPairAtIndex(mnemonic, 0);

      final account = Account(
        walletIndex: 0,
        index: 0,
        name: 'Valid Account',
        accountId: expectedKeypair.ss58Address,
        accountType: AccountType.local,
      );

      // Should not throw
      final keypair = await account.getKeypair();
      expect(keypair.ss58Address, equals(expectedKeypair.ss58Address));
    });

    test('tampered Account.fromJson with mismatched index/accountId is caught', () async {
      final hdService = HdWalletService();
      final keypairIndex0 = hdService.keyPairAtIndex(mnemonic, 0);
      final keypairIndex1 = hdService.keyPairAtIndex(mnemonic, 1);

      // Simulating a tampered JSON payload
      final tamperedAccount = Account.fromJson({
        'walletIndex': 0,
        'index': 0,
        'name': 'Spoofed account',
        'accountId': keypairIndex1.ss58Address, // Claims to be index 1's address
        'accountType': AccountType.local.name,
      });

      expect(() => tamperedAccount.getKeypair(), throwsA(isA<AccountAddressMismatchException>()));
    });
  });

  group('getKeypair() mnemonic handling', () {
    test('throws when mnemonic not found for wallet', () async {
      // Don't set up mnemonic for wallet 1
      final account = Account(
        walletIndex: 1, // Different wallet with no mnemonic
        index: 0,
        name: 'No Mnemonic Account',
        accountId: 'qzmSomeAddress',
        accountType: AccountType.local,
      );

      expect(
        () => account.getKeypair(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Mnemonic not found'))),
      );
    });
  });
}
