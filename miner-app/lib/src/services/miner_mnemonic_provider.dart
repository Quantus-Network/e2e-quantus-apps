import 'package:quantus_miner/src/services/miner_wallet_service.dart';
import 'package:quantus_sdk/src/services/mnemonic_provider.dart';

/// Miner-specific implementation of [MnemonicProvider].
///
/// This wraps [MinerWalletService] to provide the mnemonic for
/// wormhole address derivation.
class MinerMnemonicProvider implements MnemonicProvider {
  final MinerWalletService _walletService;

  MinerMnemonicProvider({MinerWalletService? walletService}) : _walletService = walletService ?? MinerWalletService();

  @override
  Future<String?> getMnemonic() => _walletService.getMnemonic();

  @override
  Future<bool> hasMnemonic() => _walletService.hasMnemonic();
}
