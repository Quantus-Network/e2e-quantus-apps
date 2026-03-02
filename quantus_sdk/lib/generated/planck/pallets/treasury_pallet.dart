// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:typed_data' as _i5;

import 'package:polkadart/polkadart.dart' as _i1;
import 'package:polkadart/scale_codec.dart' as _i3;

import '../types/pallet_treasury/pallet/call.dart' as _i7;
import '../types/quantus_runtime/runtime_call.dart' as _i6;
import '../types/sp_core/crypto/account_id32.dart' as _i2;

class Queries {
  const Queries(this.__api);

  final _i1.StateApi __api;

  final _i1.StorageValue<_i2.AccountId32> _treasuryAccount = const _i1.StorageValue<_i2.AccountId32>(
    prefix: 'TreasuryPallet',
    storage: 'TreasuryAccount',
    valueCodec: _i2.AccountId32Codec(),
  );

  final _i1.StorageValue<int> _treasuryPortion = const _i1.StorageValue<int>(
    prefix: 'TreasuryPallet',
    storage: 'TreasuryPortion',
    valueCodec: _i3.U8Codec.codec,
  );

  /// The treasury account that receives mining rewards.
  _i4.Future<_i2.AccountId32?> treasuryAccount({_i1.BlockHash? at}) async {
    final hashedKey = _treasuryAccount.hashedKey();
    final bytes = await __api.getStorage(hashedKey, at: at);
    if (bytes != null) {
      return _treasuryAccount.decodeValue(bytes);
    }
    return null; /* Nullable */
  }

  /// The portion of mining rewards that goes to treasury (0-100).
  _i4.Future<int> treasuryPortion({_i1.BlockHash? at}) async {
    final hashedKey = _treasuryPortion.hashedKey();
    final bytes = await __api.getStorage(hashedKey, at: at);
    if (bytes != null) {
      return _treasuryPortion.decodeValue(bytes);
    }
    return 0; /* Default */
  }

  /// Returns the storage key for `treasuryAccount`.
  _i5.Uint8List treasuryAccountKey() {
    final hashedKey = _treasuryAccount.hashedKey();
    return hashedKey;
  }

  /// Returns the storage key for `treasuryPortion`.
  _i5.Uint8List treasuryPortionKey() {
    final hashedKey = _treasuryPortion.hashedKey();
    return hashedKey;
  }
}

class Txs {
  const Txs();

  /// Set the treasury account. Root only.
  _i6.TreasuryPallet setTreasuryAccount({required _i2.AccountId32 account}) {
    return _i6.TreasuryPallet(_i7.SetTreasuryAccount(account: account));
  }

  /// Set the treasury portion (0-100). Root only.
  _i6.TreasuryPallet setTreasuryPortion({required int portion}) {
    return _i6.TreasuryPallet(_i7.SetTreasuryPortion(portion: portion));
  }
}
