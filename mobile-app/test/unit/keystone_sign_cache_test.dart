import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:resonance_network_wallet/v2/screens/send/keystone_sign_cache.dart';

void main() {
  group('KeystoneSignCacheKey', () {
    test('trims recipient address in fromSendParams', () {
      final key = KeystoneSignCacheKey.fromSendParams(
        accountId: 'account-a',
        recipientAddress: '  recipient  ',
        amount: BigInt.from(100),
      );

      expect(key.recipientAddress, 'recipient');
    });

    test('equal keys match regardless of recipient whitespace', () {
      final keyA = KeystoneSignCacheKey.fromSendParams(
        accountId: 'account-a',
        recipientAddress: 'recipient',
        amount: BigInt.from(100),
      );
      final keyB = KeystoneSignCacheKey.fromSendParams(
        accountId: 'account-a',
        recipientAddress: ' recipient ',
        amount: BigInt.from(100),
      );

      expect(keyA, keyB);
    });
  });

  group('KeystoneSignCacheNotifier', () {
    late KeystoneSignCacheNotifier notifier;

    setUp(() {
      notifier = KeystoneSignCacheNotifier();
    });

    final key = KeystoneSignCacheKey(accountId: 'account-a', recipientAddress: 'recipient', amount: BigInt.from(100));

    final otherKey = KeystoneSignCacheKey(
      accountId: 'account-a',
      recipientAddress: 'other-recipient',
      amount: BigInt.from(100),
    );

    UnsignedTransactionData fakeUnsignedData() {
      return UnsignedTransactionData(
        payloadToSign: QuantusSigningPayload(
          method: Uint8List(0),
          specVersion: 1,
          transactionVersion: 1,
          genesisHash: '0x00',
          blockHash: '0x00',
          blockNumber: 42,
          eraPeriod: 64,
          nonce: 0,
          tip: 0,
        ),
        signer: Uint8List(32),
        registry: Object(),
      );
    }

    test('lookup returns null when cache is empty', () {
      expect(notifier.lookup(key), isNull);
    });

    test('store and lookup return entry for matching key', () {
      final unsigned = fakeUnsignedData();
      const urParts = ['ur:part1', 'ur:part2'];

      notifier.store(key: key, unsignedData: unsigned, urParts: urParts);

      final entry = notifier.lookup(key);
      expect(entry, isNotNull);
      expect(entry!.key, key);
      expect(entry.unsignedData, unsigned);
      expect(entry.urParts, urParts);
    });

    test('lookup returns null for different key', () {
      notifier.store(key: key, unsignedData: fakeUnsignedData(), urParts: const ['ur:part1']);

      expect(notifier.lookup(otherKey), isNull);
    });

    test('startNewSendSession invalidates prior entry until re-stored', () {
      notifier.store(key: key, unsignedData: fakeUnsignedData(), urParts: const ['ur:part1']);
      expect(notifier.lookup(key), isNotNull);

      notifier.startNewSendSession();

      expect(notifier.lookup(key), isNull);
    });

    test('second startNewSendSession requires fresh store even when params unchanged', () {
      notifier.store(key: key, unsignedData: fakeUnsignedData(), urParts: const ['ur:first']);
      notifier.startNewSendSession();

      final unsigned = fakeUnsignedData();
      notifier.store(key: key, unsignedData: unsigned, urParts: const ['ur:second']);

      final entry = notifier.lookup(key);
      expect(entry, isNotNull);
      expect(entry!.urParts, const ['ur:second']);
    });
  });
}
