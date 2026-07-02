import 'package:quantus_sdk/quantus_sdk.dart';

/// Exception thrown when attempting to derive a keypair for an account type
/// that does not support local signing (e.g., keystone, external).
class UnsupportedAccountTypeForSigningException implements Exception {
  final AccountType accountType;

  UnsupportedAccountTypeForSigningException(this.accountType);

  @override
  String toString() =>
      'UnsupportedAccountTypeForSigningException: '
      'Account type "${accountType.name}" does not support local signing. '
      'Only "local" and "encrypted" accounts can derive keypairs.';
}

/// Exception thrown when the derived keypair address does not match the
/// account's stored accountId, indicating corrupted or tampered account data.
class AccountAddressMismatchException implements Exception {
  final String expectedAddress;
  final String derivedAddress;

  AccountAddressMismatchException({required this.expectedAddress, required this.derivedAddress});

  @override
  String toString() =>
      'AccountAddressMismatchException: '
      'Derived address "$derivedAddress" does not match stored accountId "$expectedAddress". '
      'Account data may be corrupted or tampered.';
}

extension HDWalletAccount on Account {
  /// Derives the keypair for this account using the appropriate derivation path.
  ///
  /// - For [AccountType.local] accounts: uses standard HD derivation at [index]
  /// - For [AccountType.encrypted] accounts: uses wormhole derivation
  ///
  /// Throws [UnsupportedAccountTypeForSigningException] for keystone/external accounts.
  /// Throws [AccountAddressMismatchException] if the derived address doesn't match [accountId].
  Future<Keypair> getKeypair() async {
    // Reject account types that don't support local signing
    if (accountType == AccountType.keystone || accountType == AccountType.external) {
      throw UnsupportedAccountTypeForSigningException(accountType);
    }

    final mnemonic = await getMnemonic();
    if (mnemonic == null) {
      throw Exception('Mnemonic not found for wallet $walletIndex');
    }

    final hdService = HdWalletService();
    final Keypair keypair;

    if (accountType == AccountType.encrypted) {
      // Encrypted accounts use wormhole derivation
      final wormholeKeyPair = hdService.deriveWormholeKeyPair(mnemonic: mnemonic, index: index);
      // For encrypted accounts, we need to verify the address matches but we can't
      // sign with a wormhole keypair directly - this is a design constraint.
      // The wormhole address is used for receiving, claims use ZK proofs.
      // For now, throw if someone tries to sign with an encrypted account.
      throw UnsupportedAccountTypeForSigningException(accountType);
    } else {
      // Local accounts use standard HD derivation
      keypair = hdService.keyPairAtIndex(mnemonic, index);
    }

    // Validate that derived address matches stored accountId
    if (keypair.ss58Address != accountId) {
      throw AccountAddressMismatchException(expectedAddress: accountId, derivedAddress: keypair.ss58Address);
    }

    return keypair;
  }

  Future<String?> getMnemonic() async {
    return SettingsService().getMnemonic(walletIndex);
  }
}
