import 'package:flutter_riverpod/legacy.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

/// Identifies a Keystone signing payload by the transfer parameters that define
/// the extrinsic call. Block height and nonce are excluded so chain drift does
/// not invalidate the cached QR within a send session.
class KeystoneSignCacheKey {
  final String accountId;
  final String recipientAddress;
  final BigInt amount;

  const KeystoneSignCacheKey({required this.accountId, required this.recipientAddress, required this.amount});

  factory KeystoneSignCacheKey.fromSendParams({
    required String accountId,
    required String recipientAddress,
    required BigInt amount,
  }) {
    return KeystoneSignCacheKey(accountId: accountId, recipientAddress: recipientAddress.trim(), amount: amount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeystoneSignCacheKey &&
          accountId == other.accountId &&
          recipientAddress == other.recipientAddress &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(accountId, recipientAddress, amount);
}

class KeystoneSignCacheEntry {
  final KeystoneSignCacheKey key;
  final UnsignedTransactionData unsignedData;
  final List<String> urParts;

  const KeystoneSignCacheEntry({required this.key, required this.unsignedData, required this.urParts});
}

class KeystoneSignCacheNotifier extends StateNotifier<KeystoneSignCacheEntry?> {
  KeystoneSignCacheNotifier() : super(null);

  void startNewSendSession() {
    state = null;
  }

  KeystoneSignCacheEntry? lookup(KeystoneSignCacheKey key) {
    final entry = state;
    if (entry == null || entry.key != key) return null;
    return entry;
  }

  void store({
    required KeystoneSignCacheKey key,
    required UnsignedTransactionData unsignedData,
    required List<String> urParts,
  }) {
    state = KeystoneSignCacheEntry(key: key, unsignedData: unsignedData, urParts: urParts);
  }

  void reset() {
    state = null;
  }
}

final keystoneSignCacheProvider = StateNotifierProvider<KeystoneSignCacheNotifier, KeystoneSignCacheEntry?>(
  (ref) => KeystoneSignCacheNotifier(),
);
