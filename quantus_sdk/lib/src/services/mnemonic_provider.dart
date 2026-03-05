/// Abstract interface for providing mnemonic phrases.
///
/// This allows different apps to provide mnemonics from different sources:
/// - Miner app: from secure storage with rewards preimage file
/// - Mobile app: from secure storage with biometric protection
/// - Tests: from memory
abstract class MnemonicProvider {
  /// Get the mnemonic phrase, or null if not available.
  Future<String?> getMnemonic();

  /// Check if a mnemonic is available without retrieving it.
  Future<bool> hasMnemonic();
}

/// Simple in-memory mnemonic provider for testing.
class InMemoryMnemonicProvider implements MnemonicProvider {
  final String? _mnemonic;

  const InMemoryMnemonicProvider(this._mnemonic);

  @override
  Future<String?> getMnemonic() async => _mnemonic;

  @override
  Future<bool> hasMnemonic() async => _mnemonic != null;
}
