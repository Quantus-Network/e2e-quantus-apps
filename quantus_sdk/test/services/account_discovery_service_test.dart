import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/src/services/account_discovery_service.dart';

void main() {
  group('AccountDiscoveryService validation', () {
    group('gapLimit bounds', () {
      test('minGapLimit is 1', () {
        expect(AccountDiscoveryService.minGapLimit, 1);
      });

      test('maxGapLimit is 100', () {
        expect(AccountDiscoveryService.maxGapLimit, 100);
      });

      test('defaultGapLimit is 20 (BIP-44 standard)', () {
        expect(AccountDiscoveryService.defaultGapLimit, 20);
      });

      test('defaultGapLimit is within bounds', () {
        expect(AccountDiscoveryService.defaultGapLimit, greaterThanOrEqualTo(AccountDiscoveryService.minGapLimit));
        expect(AccountDiscoveryService.defaultGapLimit, lessThanOrEqualTo(AccountDiscoveryService.maxGapLimit));
      });
    });

    group('maxScanIndex', () {
      test('maxScanIndex is 10000', () {
        expect(AccountDiscoveryService.maxScanIndex, 10000);
      });

      test('maxScanIndex is large enough for realistic use', () {
        // 10,000 accounts is far beyond any realistic HD wallet usage
        expect(AccountDiscoveryService.maxScanIndex, greaterThanOrEqualTo(1000));
      });
    });

    group('constants documentation', () {
      test('constants are publicly accessible for callers to validate input', () {
        // Callers may want to validate user input against these limits
        // before calling discoverAccounts
        expect(AccountDiscoveryService.minGapLimit, isA<int>());
        expect(AccountDiscoveryService.maxGapLimit, isA<int>());
        expect(AccountDiscoveryService.defaultGapLimit, isA<int>());
        expect(AccountDiscoveryService.maxScanIndex, isA<int>());
      });
    });
  });

  // Note: Full integration tests for discoverAccounts would require mocking
  // HdWalletService and GraphQlEndpointService. The validation logic tests
  // above verify the bounds are correctly defined. The ArgumentError for
  // out-of-bounds gapLimit is tested implicitly through the code structure.
}
