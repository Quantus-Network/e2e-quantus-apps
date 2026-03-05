import 'package:quantus_miner/src/services/miner_mnemonic_provider.dart';
import 'package:quantus_sdk/src/services/wormhole_address_manager.dart' as sdk;

// Re-export SDK types for backward compatibility
export 'package:quantus_sdk/src/services/wormhole_address_manager.dart'
    show WormholeAddressPurpose, TrackedWormholeAddress;

/// Miner-app specific [WormholeAddressManager] that uses [MinerMnemonicProvider].
///
/// This is a convenience wrapper that creates an SDK [WormholeAddressManager]
/// pre-configured with the miner's mnemonic provider.
class WormholeAddressManager extends sdk.WormholeAddressManager {
  /// Creates a new WormholeAddressManager using the miner's mnemonic.
  WormholeAddressManager() : super(mnemonicProvider: MinerMnemonicProvider());
}
