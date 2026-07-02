import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/quantus_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecentAddressesService bounds validation', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('rejects addresses exceeding maxAddressLength', () async {
      final service = RecentAddressesService();
      final oversizedAddress = 'qz${'A' * RecentAddressesService.maxAddressLength}';

      expect(oversizedAddress.length, greaterThan(RecentAddressesService.maxAddressLength));

      final result = await service.addAddress(oversizedAddress);

      expect(result, isFalse);
      final addresses = await service.getAddresses();
      expect(addresses, isEmpty);
    });

    test('accepts addresses at exactly maxAddressLength', () async {
      final service = RecentAddressesService();
      final maxLengthAddress = 'A' * RecentAddressesService.maxAddressLength;

      expect(maxLengthAddress.length, equals(RecentAddressesService.maxAddressLength));

      final result = await service.addAddress(maxLengthAddress);

      expect(result, isTrue);
      final addresses = await service.getAddresses();
      expect(addresses, hasLength(1));
      expect(addresses.first, equals(maxLengthAddress));
    });

    test('accepts normal-sized addresses', () async {
      final service = RecentAddressesService();
      const normalAddress = 'qz1234567890abcdef';

      final result = await service.addAddress(normalAddress);

      expect(result, isTrue);
      final addresses = await service.getAddresses();
      expect(addresses, contains(normalAddress));
    });

    test('getAddresses filters out previously stored oversized addresses', () async {
      // Simulate oversized addresses stored before the fix
      final oversizedAddress = 'qz${'A' * 1000}';
      const normalAddress = 'qz-normal-address';

      SharedPreferences.setMockInitialValues({
        'recent_addresses': [oversizedAddress, normalAddress],
      });

      final service = RecentAddressesService();
      final addresses = await service.getAddresses();

      expect(addresses, hasLength(1));
      expect(addresses.first, equals(normalAddress));
    });

    test('maxAddressLength is at least 256 to accommodate typical addresses', () {
      // Typical blockchain addresses are 32-64 chars, but some formats are longer
      expect(RecentAddressesService.maxAddressLength, greaterThanOrEqualTo(256));
    });
  });
}
