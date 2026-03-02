// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;
import 'dart:typed_data' as _i6;

import 'package:polkadart/polkadart.dart' as _i1;
import 'package:polkadart/scale_codec.dart' as _i2;

import '../types/pallet_wormhole/pallet/call.dart' as _i8;
import '../types/quantus_runtime/runtime_call.dart' as _i7;
import '../types/sp_arithmetic/per_things/permill.dart' as _i9;
import '../types/sp_core/crypto/account_id32.dart' as _i4;
import '../types/tuples_3.dart' as _i3;

class Queries {
  const Queries(this.__api);

  final _i1.StateApi __api;

  final _i1.StorageMap<List<int>, bool> _usedNullifiers = const _i1.StorageMap<List<int>, bool>(
    prefix: 'Wormhole',
    storage: 'UsedNullifiers',
    valueCodec: _i2.BoolCodec.codec,
    hasher: _i1.StorageHasher.blake2b128Concat(_i2.U8ArrayCodec(32)),
  );

  final _i1.StorageMap<_i3.Tuple5<int, BigInt, _i4.AccountId32, _i4.AccountId32, BigInt>, dynamic> _transferProof =
      const _i1.StorageMap<_i3.Tuple5<int, BigInt, _i4.AccountId32, _i4.AccountId32, BigInt>, dynamic>(
        prefix: 'Wormhole',
        storage: 'TransferProof',
        valueCodec: _i2.NullCodec.codec,
        hasher: _i1.StorageHasher.identity(
          _i3.Tuple5Codec<int, BigInt, _i4.AccountId32, _i4.AccountId32, BigInt>(
            _i2.U32Codec.codec,
            _i2.U64Codec.codec,
            _i4.AccountId32Codec(),
            _i4.AccountId32Codec(),
            _i2.U128Codec.codec,
          ),
        ),
      );

  final _i1.StorageMap<_i4.AccountId32, BigInt> _transferCount = const _i1.StorageMap<_i4.AccountId32, BigInt>(
    prefix: 'Wormhole',
    storage: 'TransferCount',
    valueCodec: _i2.U64Codec.codec,
    hasher: _i1.StorageHasher.blake2b128Concat(_i4.AccountId32Codec()),
  );

  _i5.Future<bool> usedNullifiers(List<int> key1, {_i1.BlockHash? at}) async {
    final hashedKey = _usedNullifiers.hashedKeyFor(key1);
    final bytes = await __api.getStorage(hashedKey, at: at);
    if (bytes != null) {
      return _usedNullifiers.decodeValue(bytes);
    }
    return false; /* Default */
  }

  /// Transfer proofs for wormhole transfers (both native and assets)
  _i5.Future<dynamic> transferProof(
    _i3.Tuple5<int, BigInt, _i4.AccountId32, _i4.AccountId32, BigInt> key1, {
    _i1.BlockHash? at,
  }) async {
    final hashedKey = _transferProof.hashedKeyFor(key1);
    final bytes = await __api.getStorage(hashedKey, at: at);
    if (bytes != null) {
      return _transferProof.decodeValue(bytes);
    }
    return null; /* Nullable */
  }

  /// Transfer count for all wormhole transfers
  _i5.Future<BigInt> transferCount(_i4.AccountId32 key1, {_i1.BlockHash? at}) async {
    final hashedKey = _transferCount.hashedKeyFor(key1);
    final bytes = await __api.getStorage(hashedKey, at: at);
    if (bytes != null) {
      return _transferCount.decodeValue(bytes);
    }
    return BigInt.zero; /* Default */
  }

  _i5.Future<List<bool>> multiUsedNullifiers(List<List<int>> keys, {_i1.BlockHash? at}) async {
    final hashedKeys = keys.map((key) => _usedNullifiers.hashedKeyFor(key)).toList();
    final bytes = await __api.queryStorageAt(hashedKeys, at: at);
    if (bytes.isNotEmpty) {
      return bytes.first.changes.map((v) => _usedNullifiers.decodeValue(v.key)).toList();
    }
    return (keys.map((key) => false).toList() as List<bool>); /* Default */
  }

  /// Transfer proofs for wormhole transfers (both native and assets)
  _i5.Future<List<dynamic>> multiTransferProof(
    List<_i3.Tuple5<int, BigInt, _i4.AccountId32, _i4.AccountId32, BigInt>> keys, {
    _i1.BlockHash? at,
  }) async {
    final hashedKeys = keys.map((key) => _transferProof.hashedKeyFor(key)).toList();
    final bytes = await __api.queryStorageAt(hashedKeys, at: at);
    if (bytes.isNotEmpty) {
      return bytes.first.changes.map((v) => _transferProof.decodeValue(v.key)).toList();
    }
    return []; /* Nullable */
  }

  /// Transfer count for all wormhole transfers
  _i5.Future<List<BigInt>> multiTransferCount(List<_i4.AccountId32> keys, {_i1.BlockHash? at}) async {
    final hashedKeys = keys.map((key) => _transferCount.hashedKeyFor(key)).toList();
    final bytes = await __api.queryStorageAt(hashedKeys, at: at);
    if (bytes.isNotEmpty) {
      return bytes.first.changes.map((v) => _transferCount.decodeValue(v.key)).toList();
    }
    return (keys.map((key) => BigInt.zero).toList() as List<BigInt>); /* Default */
  }

  /// Returns the storage key for `usedNullifiers`.
  _i6.Uint8List usedNullifiersKey(List<int> key1) {
    final hashedKey = _usedNullifiers.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage key for `transferProof`.
  _i6.Uint8List transferProofKey(_i3.Tuple5<int, BigInt, _i4.AccountId32, _i4.AccountId32, BigInt> key1) {
    final hashedKey = _transferProof.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage key for `transferCount`.
  _i6.Uint8List transferCountKey(_i4.AccountId32 key1) {
    final hashedKey = _transferCount.hashedKeyFor(key1);
    return hashedKey;
  }

  /// Returns the storage map key prefix for `usedNullifiers`.
  _i6.Uint8List usedNullifiersMapPrefix() {
    final hashedKey = _usedNullifiers.mapPrefix();
    return hashedKey;
  }

  /// Returns the storage map key prefix for `transferProof`.
  _i6.Uint8List transferProofMapPrefix() {
    final hashedKey = _transferProof.mapPrefix();
    return hashedKey;
  }

  /// Returns the storage map key prefix for `transferCount`.
  _i6.Uint8List transferCountMapPrefix() {
    final hashedKey = _transferCount.mapPrefix();
    return hashedKey;
  }
}

class Txs {
  const Txs();

  /// Verify an aggregated wormhole proof and process all transfers in the batch
  _i7.Wormhole verifyAggregatedProof({required List<int> proofBytes}) {
    return _i7.Wormhole(_i8.VerifyAggregatedProof(proofBytes: proofBytes));
  }
}

class Constants {
  Constants();

  /// Account ID used as the "from" account when creating transfer proofs for minted tokens
  final _i4.AccountId32 mintingAccount = const <int>[
    109,
    111,
    100,
    108,
    119,
    111,
    114,
    109,
    104,
    111,
    108,
    101,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];

  /// Minimum transfer amount required for wormhole transfers.
  /// This prevents dust transfers that waste storage.
  final BigInt minimumTransferAmount = BigInt.from(10000000000000);

  /// Volume fee rate in basis points (1 basis point = 0.01%).
  /// This must match the fee rate used in proof generation.
  final int volumeFeeRateBps = 10;

  /// Proportion of volume fees to burn (not mint). The remainder goes to the block author.
  /// Example: Permill::from_percent(50) means 50% burned, 50% to miner.
  final _i9.Permill volumeFeesBurnRate = 500000;
}
