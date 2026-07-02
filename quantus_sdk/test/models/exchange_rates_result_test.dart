import 'package:flutter_test/flutter_test.dart';
import 'package:quantus_sdk/src/models/exchange_rates_result.dart';

void main() {
  group('ExchangeRatesResult.fromJson', () {
    test('parses valid rates and expiry', () {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final validExpiry = nowUnix + 3600; // 1 hour from now

      final json = <String, dynamic>{
        'conversion_rates': <String, dynamic>{'USD': 1.0, 'EUR': 0.85, 'MYR': 3.97, 'IDR': 17337.90},
        'time_next_update_unix': validExpiry,
      };

      final result = ExchangeRatesResult.fromJson(json);

      expect(result.rates['USD'], 1.0);
      expect(result.rates['EUR'], 0.85);
      expect(result.rates['MYR'], 3.97);
      expect(result.rates['IDR'], 17337.90);
      expect(result.timeNextUpdateUnix, validExpiry);
    });

    test('filters out invalid currency codes', () {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final json = <String, dynamic>{
        'conversion_rates': <String, dynamic>{
          'USD': 1.0,
          'usd': 1.0, // lowercase - invalid
          'US': 1.0, // too short - invalid
          'USDD': 1.0, // too long - invalid
          'U1D': 1.0, // contains number - invalid
          'EUR': 0.85, // valid
          '': 1.0, // empty - invalid
          'A-B': 1.0, // contains hyphen - invalid
        },
        'time_next_update_unix': nowUnix + 3600,
      };

      final result = ExchangeRatesResult.fromJson(json);

      expect(result.rates.keys, containsAll(['USD', 'EUR']));
      expect(result.rates.length, 2);
    });

    test('filters out invalid rate values', () {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final json = <String, dynamic>{
        'conversion_rates': <String, dynamic>{
          'USD': 1.0, // valid
          'NEG': -1.0, // negative - invalid
          'ZER': 0.0, // zero (below minRate) - invalid
          'INF': double.infinity, // infinite - invalid
          'NAN': double.nan, // NaN - invalid
          'BIG': 1e8, // too large (> maxRate) - invalid
          'SML': 1e-7, // too small (< minRate) - invalid
          'EUR': 0.85, // valid
          'IDR': 17337.90, // valid (within range)
        },
        'time_next_update_unix': nowUnix + 3600,
      };

      final result = ExchangeRatesResult.fromJson(json);

      expect(result.rates.keys, containsAll(['USD', 'EUR', 'IDR']));
      expect(result.rates.length, 3);
      expect(result.rates.containsKey('NEG'), false);
      expect(result.rates.containsKey('ZER'), false);
      expect(result.rates.containsKey('INF'), false);
      expect(result.rates.containsKey('NAN'), false);
      expect(result.rates.containsKey('BIG'), false);
      expect(result.rates.containsKey('SML'), false);
    });

    test('caps expiry at maximum allowed (7 days)', () {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final farFutureExpiry = nowUnix + (365 * 24 * 60 * 60); // 1 year from now

      final json = <String, dynamic>{
        'conversion_rates': <String, dynamic>{'USD': 1.0},
        'time_next_update_unix': farFutureExpiry,
      };

      final result = ExchangeRatesResult.fromJson(json);

      // Should be capped at ~7 days from now
      final maxAllowed = nowUnix + ExchangeRatesResult.maxExpirySeconds;
      expect(result.timeNextUpdateUnix, maxAllowed);
      expect(result.timeNextUpdateUnix, lessThan(farFutureExpiry));
    });

    test('does not modify expiry within allowed range', () {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final validExpiry = nowUnix + (2 * 24 * 60 * 60); // 2 days from now

      final json = <String, dynamic>{
        'conversion_rates': <String, dynamic>{'USD': 1.0},
        'time_next_update_unix': validExpiry,
      };

      final result = ExchangeRatesResult.fromJson(json);

      expect(result.timeNextUpdateUnix, validExpiry);
    });

    test('handles integer rate values', () {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final json = <String, dynamic>{
        'conversion_rates': <String, dynamic>{
          'USD': 1, // int, not double
          'JPY': 156, // int
        },
        'time_next_update_unix': nowUnix + 3600,
      };

      final result = ExchangeRatesResult.fromJson(json);

      expect(result.rates['USD'], 1.0);
      expect(result.rates['JPY'], 156.0);
    });

    test('skips non-numeric rate values', () {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final json = <String, dynamic>{
        'conversion_rates': <String, dynamic>{
          'USD': 1.0,
          'STR': '1.0', // string - invalid
          'NUL': null, // null - invalid
          'LST': [1.0], // list - invalid
          'MAP': {'value': 1.0}, // map - invalid
        },
        'time_next_update_unix': nowUnix + 3600,
      };

      final result = ExchangeRatesResult.fromJson(json);

      expect(result.rates.length, 1);
      expect(result.rates['USD'], 1.0);
    });

    test('returns empty rates map when all rates are invalid', () {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final json = <String, dynamic>{
        'conversion_rates': <String, dynamic>{'invalid': -1.0, '': 0.0},
        'time_next_update_unix': nowUnix + 3600,
      };

      final result = ExchangeRatesResult.fromJson(json);

      expect(result.rates, isEmpty);
    });

    test('boundary rate values are accepted', () {
      final nowUnix = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final json = <String, dynamic>{
        'conversion_rates': <String, dynamic>{
          'MIN': ExchangeRatesResult.minRate, // exactly at minimum
          'MAX': ExchangeRatesResult.maxRate, // exactly at maximum
        },
        'time_next_update_unix': nowUnix + 3600,
      };

      final result = ExchangeRatesResult.fromJson(json);

      expect(result.rates['MIN'], ExchangeRatesResult.minRate);
      expect(result.rates['MAX'], ExchangeRatesResult.maxRate);
    });
  });
}
