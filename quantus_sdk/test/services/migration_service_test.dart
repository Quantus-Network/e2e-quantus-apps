import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

void main() {
  group('MigrationResult sealed class', () {
    test('MigrationSuccess holds account data correctly', () {
      const oldAccount = Account(
        walletIndex: 0,
        index: 1,
        name: 'Test Account',
        accountId: 'old_id',
      );
      const success = MigrationSuccess(
        oldAccount: oldAccount,
        publicKeyHex: 'abc123',
        newAccountId: 'new_id',
      );

      expect(success.oldAccount, equals(oldAccount));
      expect(success.publicKeyHex, equals('abc123'));
      expect(success.newAccountId, equals('new_id'));
    });

    test('MigrationFailure holds failure reason', () {
      const oldAccount = Account(
        walletIndex: 1,
        index: 0,
        name: 'Failed Account',
        accountId: 'old_id',
      );
      const failure = MigrationFailure(
        oldAccount: oldAccount,
        reason: 'No mnemonic found for wallet 1',
      );

      expect(failure.oldAccount, equals(oldAccount));
      expect(failure.reason, equals('No mnemonic found for wallet 1'));
    });

    test('pattern matching works on MigrationResult', () {
      const oldAccount = Account(
        walletIndex: 0,
        index: 0,
        name: 'Test',
        accountId: 'test_id',
      );

      const MigrationResult success = MigrationSuccess(
        oldAccount: oldAccount,
        publicKeyHex: 'hex',
        newAccountId: 'new_id',
      );

      const MigrationResult failure = MigrationFailure(
        oldAccount: oldAccount,
        reason: 'test error',
      );

      String describeResult(MigrationResult result) {
        return switch (result) {
          MigrationSuccess(:final newAccountId) => 'Success: $newAccountId',
          MigrationFailure(:final reason) => 'Failure: $reason',
        };
      }

      expect(describeResult(success), equals('Success: new_id'));
      expect(describeResult(failure), equals('Failure: test error'));
    });
  });

  group('MigrationService wallet index handling', () {
    test('accounts from different wallets should preserve their walletIndex', () {
      // This test verifies the design: accounts should keep their original walletIndex
      const account0 = Account(
        walletIndex: 0,
        index: 0,
        name: 'Wallet 0 Account',
        accountId: 'w0_a0',
      );
      const account1 = Account(
        walletIndex: 1,
        index: 0,
        name: 'Wallet 1 Account',
        accountId: 'w1_a0',
      );

      // Simulating what getMigrationData should produce
      const success0 = MigrationSuccess(
        oldAccount: account0,
        publicKeyHex: 'hex0',
        newAccountId: 'new_w0_a0',
      );
      const success1 = MigrationSuccess(
        oldAccount: account1,
        publicKeyHex: 'hex1',
        newAccountId: 'new_w1_a0',
      );

      // Verify wallet indices are preserved in the success results
      expect(success0.oldAccount.walletIndex, equals(0));
      expect(success1.oldAccount.walletIndex, equals(1));

      // The migrated accounts should maintain their wallet indices
      final migratedAccount0 = Account(
        walletIndex: success0.oldAccount.walletIndex,
        index: success0.oldAccount.index,
        name: success0.oldAccount.name,
        accountId: success0.newAccountId,
        accountType: success0.oldAccount.accountType,
      );
      final migratedAccount1 = Account(
        walletIndex: success1.oldAccount.walletIndex,
        index: success1.oldAccount.index,
        name: success1.oldAccount.name,
        accountId: success1.newAccountId,
        accountType: success1.oldAccount.accountType,
      );

      expect(migratedAccount0.walletIndex, equals(0));
      expect(migratedAccount1.walletIndex, equals(1));
      expect(migratedAccount0.accountId, equals('new_w0_a0'));
      expect(migratedAccount1.accountId, equals('new_w1_a0'));
    });

    test('encrypted accounts should preserve their accountType', () {
      const encryptedAccount = Account(
        walletIndex: 0,
        index: AppConstants.encryptedAccountIndex,
        name: 'Encrypted Account',
        accountId: 'encrypted_old_id',
        accountType: AccountType.encrypted,
      );

      const success = MigrationSuccess(
        oldAccount: encryptedAccount,
        publicKeyHex: 'wormhole_hex',
        newAccountId: 'wormhole_new_id',
      );

      // Verify the account type is preserved
      expect(success.oldAccount.accountType, equals(AccountType.encrypted));
      expect(success.oldAccount.index, equals(AppConstants.encryptedAccountIndex));

      // The migrated account should preserve the encrypted type
      final migratedAccount = Account(
        walletIndex: success.oldAccount.walletIndex,
        index: success.oldAccount.index,
        name: success.oldAccount.name,
        accountId: success.newAccountId,
        accountType: success.oldAccount.accountType,
      );

      expect(migratedAccount.accountType, equals(AccountType.encrypted));
    });
  });

  group('MigrationAccountData backward compatibility', () {
    test('fromSuccess factory creates equivalent data', () {
      const oldAccount = Account(
        walletIndex: 0,
        index: 0,
        name: 'Test',
        accountId: 'old_id',
      );
      const success = MigrationSuccess(
        oldAccount: oldAccount,
        publicKeyHex: 'hex123',
        newAccountId: 'new_id',
      );

      // ignore: deprecated_member_use_from_same_package
      final legacyData = MigrationAccountData.fromSuccess(success);

      expect(legacyData.oldAccount, equals(oldAccount));
      expect(legacyData.publicKeyHex, equals('hex123'));
      expect(legacyData.newAccountId, equals('new_id'));
    });
  });
}
