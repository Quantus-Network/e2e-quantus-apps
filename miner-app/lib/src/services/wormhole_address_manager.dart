import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:quantus_miner/src/services/miner_wallet_service.dart';
import 'package:quantus_miner/src/utils/app_logger.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

final _log = log.withTag('WormholeAddressManager');

/// Purpose values for wormhole HD derivation.
/// These match the values in quantus_sdk's WormholePurpose.
class WormholeAddressPurpose {
  /// Change addresses for wormhole withdrawals.
  static const int change = 0;

  /// Miner rewards (primary address).
  static const int minerRewards = 1;
}

/// Information about a tracked wormhole address.
class TrackedWormholeAddress {
  /// The wormhole address (SS58 format).
  final String address;

  /// The HD derivation purpose.
  final int purpose;

  /// The HD derivation index.
  final int index;

  /// The secret for this address (hex encoded, needed for proofs).
  final String secretHex;

  /// Whether this is the primary miner rewards address.
  bool get isPrimary => purpose == WormholeAddressPurpose.minerRewards && index == 0;

  const TrackedWormholeAddress({
    required this.address,
    required this.purpose,
    required this.index,
    required this.secretHex,
  });

  Map<String, dynamic> toJson() => {
    'address': address,
    'purpose': purpose,
    'index': index,
    'secretHex': secretHex,
  };

  factory TrackedWormholeAddress.fromJson(Map<String, dynamic> json) {
    return TrackedWormholeAddress(
      address: json['address'] as String,
      purpose: json['purpose'] as int,
      index: json['index'] as int,
      secretHex: json['secretHex'] as String,
    );
  }

  @override
  String toString() => 'TrackedWormholeAddress($address, purpose=$purpose, index=$index)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackedWormholeAddress && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}

/// Manages multiple wormhole addresses for a wallet.
///
/// This service tracks:
/// - The primary miner rewards address (purpose=1, index=0)
/// - Change addresses generated during partial withdrawals (purpose=0, index=N)
///
/// All addresses are derived from the same mnemonic using HD derivation.
class WormholeAddressManager {
  static const String _storageFileName = 'wormhole_addresses.json';

  final MinerWalletService _walletService;
  final WormholeService _wormholeService;

  /// All tracked addresses, keyed by SS58 address.
  final Map<String, TrackedWormholeAddress> _addresses = {};

  /// The next change address index to use.
  int _nextChangeIndex = 0;

  WormholeAddressManager({
    MinerWalletService? walletService,
    WormholeService? wormholeService,
  }) : _walletService = walletService ?? MinerWalletService(),
       _wormholeService = wormholeService ?? WormholeService();

  /// Get all tracked addresses.
  List<TrackedWormholeAddress> get allAddresses => _addresses.values.toList();

  /// Get all address strings (SS58 format).
  Set<String> get allAddressStrings => _addresses.keys.toSet();

  /// Get the primary miner rewards address.
  TrackedWormholeAddress? get primaryAddress {
    return _addresses.values.where((a) => a.isPrimary).firstOrNull;
  }

  /// Get a tracked address by its SS58 string.
  TrackedWormholeAddress? getAddress(String address) => _addresses[address];

  /// Check if an address is tracked.
  bool isTracked(String address) => _addresses.containsKey(address);

  /// Initialize the manager and load tracked addresses.
  ///
  /// This should be called on app startup after the wallet is set up.
  Future<void> initialize() async {
    await _loadFromDisk();

    // Ensure the primary address is tracked
    final mnemonic = await _walletService.getMnemonic();
    if (mnemonic != null) {
      await _ensurePrimaryAddressTracked(mnemonic);
    }
  }

  /// Ensure the primary miner rewards address is tracked.
  Future<void> _ensurePrimaryAddressTracked(String mnemonic) async {
    final keyPair = _wormholeService.deriveMinerRewardsKeyPair(
      mnemonic: mnemonic,
      index: 0,
    );

    if (!_addresses.containsKey(keyPair.address)) {
      final tracked = TrackedWormholeAddress(
        address: keyPair.address,
        purpose: WormholeAddressPurpose.minerRewards,
        index: 0,
        secretHex: keyPair.secretHex,
      );
      _addresses[keyPair.address] = tracked;
      await _saveToDisk();
      _log.i('Added primary miner rewards address: ${keyPair.address}');
    }
  }

  /// Derive and track a new change address.
  ///
  /// Returns the new address. The address is immediately persisted.
  Future<TrackedWormholeAddress> deriveNextChangeAddress() async {
    final mnemonic = await _walletService.getMnemonic();
    if (mnemonic == null) {
      throw StateError('No mnemonic available - cannot derive change address');
    }

    final keyPair = _wormholeService.deriveKeyPair(
      mnemonic: mnemonic,
      purpose: WormholeAddressPurpose.change,
      index: _nextChangeIndex,
    );

    final tracked = TrackedWormholeAddress(
      address: keyPair.address,
      purpose: WormholeAddressPurpose.change,
      index: _nextChangeIndex,
      secretHex: keyPair.secretHex,
    );

    _addresses[keyPair.address] = tracked;
    _nextChangeIndex++;
    await _saveToDisk();

    _log.i('Derived new change address: ${keyPair.address} (index=${tracked.index})');
    return tracked;
  }

  /// Re-derive all addresses from the mnemonic.
  ///
  /// This is useful after restoring from backup or when the secrets
  /// need to be regenerated.
  Future<void> rederiveAllSecrets() async {
    final mnemonic = await _walletService.getMnemonic();
    if (mnemonic == null) {
      _log.w('No mnemonic available - cannot rederive secrets');
      return;
    }

    final updatedAddresses = <String, TrackedWormholeAddress>{};

    for (final tracked in _addresses.values) {
      final keyPair = _wormholeService.deriveKeyPair(
        mnemonic: mnemonic,
        purpose: tracked.purpose,
        index: tracked.index,
      );

      // Verify the derived address matches
      if (keyPair.address != tracked.address) {
        _log.w('Address mismatch during rederivation: expected ${tracked.address}, got ${keyPair.address}');
        continue;
      }

      updatedAddresses[keyPair.address] = TrackedWormholeAddress(
        address: keyPair.address,
        purpose: tracked.purpose,
        index: tracked.index,
        secretHex: keyPair.secretHex,
      );
    }

    _addresses
      ..clear()
      ..addAll(updatedAddresses);
    await _saveToDisk();
    _log.i('Rederived secrets for ${_addresses.length} addresses');
  }

  /// Load tracked addresses from disk.
  Future<void> _loadFromDisk() async {
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        _addresses.clear();
        final addressesData = data['addresses'] as List<dynamic>?;
        if (addressesData != null) {
          for (final item in addressesData) {
            final tracked = TrackedWormholeAddress.fromJson(item as Map<String, dynamic>);
            _addresses[tracked.address] = tracked;
          }
        }

        _nextChangeIndex = data['nextChangeIndex'] as int? ?? 0;
        _log.i('Loaded ${_addresses.length} tracked addresses from disk');
      }
    } catch (e) {
      _log.e('Failed to load addresses from disk', error: e);
    }
  }

  /// Save tracked addresses to disk.
  Future<void> _saveToDisk() async {
    try {
      final file = await _getStorageFile();
      final data = {
        'nextChangeIndex': _nextChangeIndex,
        'addresses': _addresses.values.map((a) => a.toJson()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
      _log.d('Saved ${_addresses.length} addresses to disk');
    } catch (e) {
      _log.e('Failed to save addresses to disk', error: e);
    }
  }

  Future<File> _getStorageFile() async {
    final appDir = await getApplicationSupportDirectory();
    final quantusDir = Directory('${appDir.path}/.quantus');
    if (!await quantusDir.exists()) {
      await quantusDir.create(recursive: true);
    }
    return File('${quantusDir.path}/$_storageFileName');
  }

  /// Clear all tracked addresses (for reset/logout).
  Future<void> clearAll() async {
    _addresses.clear();
    _nextChangeIndex = 0;
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        await file.delete();
        _log.i('Deleted wormhole addresses file');
      }
    } catch (e) {
      _log.e('Failed to delete addresses file', error: e);
    }
  }
}
