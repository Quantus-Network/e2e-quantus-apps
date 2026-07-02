import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';

class _ControlledHdWalletService extends HdWalletService {
  @override
  WormholeKeyPair deriveWormholeKeyPair({required String mnemonic, int index = 0}) {
    final suffix = mnemonic.runes.fold<int>(0, (sum, rune) => sum + rune).toRadixString(16);
    return WormholeKeyPair(
      address: 'addr-$suffix',
      addressHex: 'hex-$suffix',
      rewardsPreimageHex: 'rewards-$suffix',
      secretHex: 'secret-$suffix',
    );
  }
}

void main() {
  group('WormholeAddressManager lifecycle', () {
    test('clear() invalidates in-flight initialize() calls', () async {
      final mnemonicRequest = Completer<String?>();
      final manager = WormholeAddressManager(
        getMnemonic: () => mnemonicRequest.future,
        hdWalletService: _ControlledHdWalletService(),
      );

      // Start initialize but don't complete it yet
      final initializeFuture = manager.initialize();

      // Clear while initialize is still awaiting
      manager.clear();
      expect(manager.primary, isNull, reason: 'clear() should remove any currently cached key pair');

      // Now complete the mnemonic request
      mnemonicRequest.complete('late mnemonic value');
      await initializeFuture;

      // The stale initialize should NOT have restored primary
      expect(
        manager.primary,
        isNull,
        reason: 'stale initialize() continuation should not restore primary after clear()',
      );
    });

    test('initialize() works normally when not cleared', () async {
      final mnemonicRequest = Completer<String?>();
      final manager = WormholeAddressManager(
        getMnemonic: () => mnemonicRequest.future,
        hdWalletService: _ControlledHdWalletService(),
      );

      final initializeFuture = manager.initialize();
      mnemonicRequest.complete('test mnemonic');
      await initializeFuture;

      expect(manager.primary, isNotNull);
      expect(manager.primary!.secretHex, isNotEmpty);
    });

    test('multiple clear() calls increment generation correctly', () async {
      final requests = <Completer<String?>>[];
      var requestIndex = 0;

      final manager = WormholeAddressManager(
        getMnemonic: () {
          final completer = Completer<String?>();
          requests.add(completer);
          return completer.future;
        },
        hdWalletService: _ControlledHdWalletService(),
      );

      // Start first initialize
      final init1 = manager.initialize();
      manager.clear();

      // Start second initialize
      final init2 = manager.initialize();
      manager.clear();

      // Start third initialize (this one should succeed)
      final init3 = manager.initialize();

      // Complete all requests
      requests[0].complete('mnemonic1');
      requests[1].complete('mnemonic2');
      requests[2].complete('mnemonic3');

      await init1;
      await init2;
      await init3;

      // Only the third initialize should have set primary
      expect(manager.primary, isNotNull);
      expect(
        manager.primary!.address,
        contains('mnemonic3'.runes.fold<int>(0, (sum, rune) => sum + rune).toRadixString(16)),
      );
    });
  });
}
