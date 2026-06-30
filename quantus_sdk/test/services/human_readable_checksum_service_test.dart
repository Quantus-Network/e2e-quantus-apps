import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/src/services/human_readable_checksum_service.dart';

void main() {
  group('HumanReadableChecksumService bounds', () {
    late HumanReadableChecksumService service;

    setUp(() {
      service = HumanReadableChecksumService();
    });

    test('rejects empty address without initializing isolate', () async {
      // Empty address should be rejected immediately, before any isolate work
      final result = await service.getHumanReadableName('');
      expect(result, equals(''));
    });

    test('rejects oversized address without initializing isolate', () async {
      // Create a string longer than maxAddressLength (64)
      // Should be rejected immediately, before any isolate work
      final oversizedAddress = 'q' * 65;
      final result = await service.getHumanReadableName(oversizedAddress);
      expect(result, equals(''));
    });

    test('rejects very long address (DoS prevention)', () async {
      // Simulate an attacker sending a huge string
      final hugeAddress = 'q' * 10000;
      final result = await service.getHumanReadableName(hugeAddress);
      expect(result, equals(''));
    });

    test('maxAddressLength constant is reasonable for SS58', () {
      // SS58 addresses are typically 47-50 characters
      // maxAddressLength should be larger to accommodate edge cases
      expect(HumanReadableChecksumService.maxAddressLength, greaterThanOrEqualTo(50));
      // But not excessively large
      expect(HumanReadableChecksumService.maxAddressLength, lessThanOrEqualTo(128));
    });

    test('maxCacheSize constant is bounded', () {
      // Cache should have a reasonable upper bound
      expect(HumanReadableChecksumService.maxCacheSize, greaterThan(0));
      expect(HumanReadableChecksumService.maxCacheSize, lessThanOrEqualTo(10000));
    });
  });
}
