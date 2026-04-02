import 'package:quantus_miner/src/services/miner_mnemonic_provider.dart';
import 'package:quantus_sdk/src/services/wormhole_address_manager.dart' as sdk;

// Re-export SDK types for backward compatibility
export 'package:quantus_sdk/src/services/wormhole_address_manager.dart'
    show WormholeAddressPurpose, TrackedWormholeAddress;

/// Miner-app specific [WormholeAddressManager] that uses [MinerMnemonicProvider].
///
/// This is a singleton convenience wrapper that creates an SDK [WormholeAddressManager]
/// pre-configured with the miner's mnemonic provider.
///
/// Use `WormholeAddressManager()` to get the instance.
class WormholeAddressManager extends sdk.WormholeAddressManager {
  // Singleton
  static final WormholeAddressManager _instance =
      WormholeAddressManager._internal();
  factory WormholeAddressManager() => _instance;

  WormholeAddressManager._internal()
    : super(mnemonicProvider: MinerMnemonicProvider());
}
